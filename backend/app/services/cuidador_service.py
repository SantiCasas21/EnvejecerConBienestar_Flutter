"""Servicio de gestión y supervisión de pacientes para cuidadores."""
from typing import List, Dict, Any, Optional
from datetime import datetime
from app.extensions import db
from app.models.usuario import Usuario
from app.models.perfil import PerfilUsuario
from app.models.medicamento import Medicamento
from app.models.meta import Meta
from app.models.cuidador_paciente import CuidadorPaciente
from app.models.tratamiento import Tratamiento
from app.services.tratamiento_service import TratamientoService

class CuidadorService:
    """Lógica de negocio para vinculación y supervisión de pacientes."""

    @staticmethod
    def vincular_paciente(
        cuidador_id: int,
        codigo_vinculacion: str,
        parentesco: str = "Familiar / Cuidador"
    ) -> Dict[str, Any]:
        """
        Vincula a un Cuidador con un Adulto Mayor mediante su código único.

        :param cuidador_id: ID del usuario cuidador en sesión.
        :param codigo_vinculacion: Código alfanumérico secuencial (ej: ECB-1001).
        :param parentesco: Parentesco o rol del cuidador respecto al paciente.
        :return: Diccionario con la confirmación y datos del paciente vinculado.
        :raises ValueError: Si el código es inválido o no existe el paciente.
        """
        codigo_limpio = (codigo_vinculacion or "").strip().upper()
        if not codigo_limpio:
            raise ValueError("El código de vinculación no puede estar vacío.")

        # Buscar paciente por código
        paciente = Usuario.query.filter_by(codigo_vinculacion=codigo_limpio).first()
        if not paciente:
            raise LookupError(f"No encontramos ningún adulto mayor registrado con el código '{codigo_limpio}'.")

        if paciente.id == cuidador_id:
            raise ValueError("No puedes vincularte a ti mismo como paciente.")

        # Verificar si ya existe el vínculo
        vinculo_existente = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente.id
        ).first()

        if vinculo_existente:
            # Si ya existía, actualizamos el parentesco si cambió
            if parentesco and vinculo_existente.parentesco != parentesco:
                vinculo_existente.parentesco = parentesco
                db.session.commit()
            return {
                "msg": f"El paciente {paciente.nombre} ya se encuentra vinculado a tu cuenta.",
                "mensaje": f"El paciente {paciente.nombre} ya se encuentra vinculado a tu cuenta.",
                "paciente": paciente.to_dict(),
                "parentesco": vinculo_existente.parentesco,
                "ya_vinculado": True
            }

        try:
            nuevo_vinculo = CuidadorPaciente(
                cuidador_id=cuidador_id,
                paciente_id=paciente.id,
                parentesco=parentesco or "Familiar / Cuidador"
            )
            db.session.add(nuevo_vinculo)
            db.session.commit()

            return {
                "mensaje": f"¡Has vinculado exitosamente a {paciente.nombre}!",
                "paciente": paciente.to_dict(),
                "parentesco": nuevo_vinculo.parentesco,
                "ya_vinculado": False
            }
        except Exception as e:
            db.session.rollback()
            raise RuntimeError(f"Error al guardar la vinculación: {str(e)}")

    @staticmethod
    def get_pacientes_cuidador(cuidador_id: int) -> List[Dict[str, Any]]:
        """
        Obtiene la lista de pacientes supervisados por un cuidador de forma optimizada (evitando N+1),
        incluyendo indicadores en tiempo real de tomas de medicamentos y alertas de botiquín.

        :param cuidador_id: ID del usuario cuidador.
        :return: Lista de diccionarios con métricas y datos de cada paciente.
        """
        # 1. Obtener vínculos del cuidador
        vinculos = CuidadorPaciente.query.filter_by(cuidador_id=cuidador_id).all()
        if not vinculos:
            return []

        paciente_ids = [v.paciente_id for v in vinculos]
        parentesco_por_paciente = {v.paciente_id: v.parentesco for v in vinculos}
        fecha_vinculo_por_paciente = {
            v.paciente_id: v.created_at.isoformat() if v.created_at else None
            for v in vinculos
        }

        # 2. Cargar en lote todos los pacientes
        pacientes = Usuario.query.filter(Usuario.id.in_(paciente_ids)).all()
        pacientes_dict = {p.id: p for p in pacientes}

        # 3. Cargar en lote perfiles de los pacientes
        perfiles = PerfilUsuario.query.filter(PerfilUsuario.usuario_id.in_(paciente_ids)).all()
        perfiles_dict = {p.usuario_id: p for p in perfiles}

        # 4. Cargar en lote todos los medicamentos de estos pacientes
        medicamentos = Medicamento.query.filter(Medicamento.usuario_id.in_(paciente_ids)).all()
        meds_por_paciente: Dict[int, List[Medicamento]] = {pid: [] for pid in paciente_ids}
        for med in medicamentos:
            meds_por_paciente.setdefault(med.usuario_id, []).append(med)

        # 5. Construir respuesta enriquecida sin consultas adicionales
        resultado: List[Dict[str, Any]] = []

        for pid in paciente_ids:
            paciente = pacientes_dict.get(pid)
            if not paciente:
                continue

            perfil = perfiles_dict.get(pid)
            lista_meds = meds_por_paciente.get(pid, [])

            # Cálculos de tomas y stock
            total_meds = len(lista_meds)
            tomas_cumplidas = sum(1 for m in lista_meds if m.esta_tomado)
            tomas_pendientes = total_meds - tomas_cumplidas

            # Alertas de inventario (pastillas <= 5 o según umbral de alerta)
            meds_en_alerta = [
                m.nombre for m in lista_meds
                if (m.cantidad_restante is not None and m.cantidad_restante <= (m.umbral_alerta or 5))
            ]

            # Próxima medicina pendiente
            proxima_med = next((m for m in lista_meds if not m.esta_tomado), None)
            proxima_toma_info = None
            if proxima_med:
                hora_str = proxima_med.hora_alarma.strftime("%H:%M") if proxima_med.hora_alarma else None
                proxima_toma_info = {
                    "nombre": proxima_med.nombre,
                    "miligramos": proxima_med.miligramos,
                    "hora": hora_str,
                    "icono": proxima_med.icono or "💊"
                }

            telefono_contacto = (
                perfil.telefono if perfil and perfil.telefono
                else (perfil.contacto_emergencia_telefono if perfil else None)
            )

            lista_meds_data = [
                {
                    "id": m.id,
                    "nombre": m.nombre,
                    "miligramos": m.miligramos,
                    "notas": m.notas,
                    "frecuencia": m.frecuencia,
                    "hora_alarma": m.hora_alarma.strftime("%H:%M") if m.hora_alarma else "08:00",
                    "esta_tomado": bool(m.esta_tomado),
                    "cantidad_restante": m.cantidad_restante,
                    "umbral_alerta": m.umbral_alerta,
                    "alerta_inventario": (m.cantidad_restante is not None and m.cantidad_restante <= (m.umbral_alerta or 5)),
                    "dias_autonomia": m.dias_autonomia,
                    "icono": m.icono or "💊"
                }
                for m in lista_meds
            ]

            resultado.append({
                "id": paciente.id,
                "nombre": paciente.nombre,
                "email": paciente.email,
                "codigo_vinculacion": paciente.codigo_vinculacion,
                "parentesco": parentesco_por_paciente.get(pid, "Familiar"),
                "fecha_vinculacion": fecha_vinculo_por_paciente.get(pid),
                "edad": perfil.edad if perfil else None,
                "genero": perfil.genero if perfil else None,
                "tipo_sangre": perfil.tipo_sangre if perfil else None,
                "eps": perfil.eps if perfil else None,
                "alergias": perfil.alergias if perfil else None,
                "condiciones": perfil.condiciones if perfil else None,
                "telefono": telefono_contacto,
                "contacto_emergencia_nombre": perfil.contacto_emergencia_nombre if perfil else None,
                "contacto_emergencia_telefono": perfil.contacto_emergencia_telefono if perfil else None,
                "total_medicamentos": total_meds,
                "tomas_cumplidas": tomas_cumplidas,
                "tomas_pendientes": tomas_pendientes,
                "alertas_stock": len(meds_en_alerta),
                "medicamentos_alerta": meds_en_alerta,
                "proxima_toma": proxima_toma_info,
                "medicamentos": lista_meds_data,
            })

        return resultado

    @staticmethod
    def get_detalle_paciente(cuidador_id: int, paciente_id: int) -> Dict[str, Any]:
        """
        Obtiene el detalle clínico y operativo completo de un paciente supervisado.

        :param cuidador_id: ID del usuario cuidador.
        :param paciente_id: ID del paciente a consultar.
        :return: Diccionario con perfil, medicamentos detallados y metas de salud.
        :raises PermissionError: Si el cuidador no está vinculado al paciente.
        :raises ValueError: Si el paciente no existe.
        """
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            raise PermissionError("No tienes autorización para supervisar a este paciente.")

        paciente = Usuario.query.get(paciente_id)
        if not paciente:
            raise ValueError("Paciente no encontrado.")

        perfil = PerfilUsuario.query.filter_by(usuario_id=paciente_id).first()
        medicamentos = Medicamento.query.filter_by(usuario_id=paciente_id).all()
        metas = Meta.query.filter_by(usuario_id=paciente_id).all()
        tratamientos = Tratamiento.query.filter_by(usuario_id=paciente_id).order_by(Tratamiento.id.desc()).all()

        meds_data = []
        meds_alerta = []
        for m in medicamentos:
            es_alerta = m.cantidad_restante is not None and m.cantidad_restante <= (m.umbral_alerta or 5)
            if es_alerta:
                meds_alerta.append(m.nombre)

            meds_data.append({
                "id": m.id,
                "nombre": m.nombre,
                "miligramos": m.miligramos,
                "notas": m.notas,
                "frecuencia": m.frecuencia,
                "hora_alarma": m.hora_alarma.strftime("%H:%M") if m.hora_alarma else None,
                "esta_tomado": m.esta_tomado,
                "cantidad_restante": m.cantidad_restante,
                "umbral_alerta": m.umbral_alerta,
                "alerta_inventario": es_alerta,
                "icono": m.icono or "💊",
                "dias_autonomia": m.dias_autonomia
            })

        metas_data = [
            {
                "id": meta.id,
                "nombre": meta.nombre,
                "objetivo": meta.objetivo,
                "progreso": meta.progreso,
                "unidad": meta.unidad,
                "icono": meta.icono,
                "completada": meta.completada
            }
            for meta in metas
        ]

        perfil_data = perfil.to_dict() if hasattr(perfil, 'to_dict') else (
            {
                "edad": perfil.edad if perfil else None,
                "genero": perfil.genero if perfil else None,
                "tipo_sangre": perfil.tipo_sangre if perfil else None,
                "eps": perfil.eps if perfil else None,
                "alergias": perfil.alergias if perfil else None,
                "condiciones": perfil.condiciones if perfil else None,
                "telefono": perfil.telefono if perfil else None,
                "contacto_emergencia_nombre": perfil.contacto_emergencia_nombre if perfil else None,
                "contacto_emergencia_telefono": perfil.contacto_emergencia_telefono if perfil else None,
                "medico_tratante": perfil.medico_tratante if perfil else None,
                "telefono_medico": perfil.telefono_medico if perfil else None,
                "clinica_preferida": perfil.clinica_preferida if perfil else None,
            } if perfil else {}
        )

        return {
            "paciente": {
                "id": paciente.id,
                "nombre": paciente.nombre,
                "email": paciente.email,
                "codigo_vinculacion": paciente.codigo_vinculacion,
                "parentesco": vinculo.parentesco,
                "fecha_vinculacion": vinculo.created_at.isoformat() if vinculo.created_at else None,
            },
            "perfil": perfil_data,
            "medicamentos": meds_data,
            "tratamientos": [t.to_dict() for t in tratamientos],
            "alertas_inventario": meds_alerta,
            "metas": metas_data,
            "resumen_dia": {
                "total": len(medicamentos),
                "cumplidas": sum(1 for m in medicamentos if m.esta_tomado),
                "pendientes": sum(1 for m in medicamentos if not m.esta_tomado),
                "alertas_stock": len(meds_alerta)
            }
        }

    @staticmethod
    def desvincular_paciente(cuidador_id: int, paciente_id: int) -> bool:
        """
        Desvincula a un paciente de la supervisión del cuidador.

        :param cuidador_id: ID del usuario cuidador.
        :param paciente_id: ID del paciente a desvincular.
        :return: True si se eliminó exitosamente, False si no existía el vínculo.
        """
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            return False

        try:
            db.session.delete(vinculo)
            db.session.commit()
            return True
        except Exception:
            db.session.rollback()
            raise

    @staticmethod
    def get_medicamentos_paciente(cuidador_id: int, paciente_id: int) -> List[Dict[str, Any]]:
        """
        Obtiene la lista de medicamentos de un paciente supervisado por el cuidador.

        :param cuidador_id: ID del usuario cuidador.
        :param paciente_id: ID del paciente a consultar.
        :return: Lista de medicamentos serializados con métricas de inventario y estado.
        :raises PermissionError: Si el cuidador no está vinculado al paciente.
        """
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            raise PermissionError("No tienes autorización para consultar los medicamentos de este paciente.")

        medicamentos = Medicamento.query.filter_by(usuario_id=paciente_id).order_by(
            Medicamento.esta_tomado.asc(), Medicamento.id.asc()
        ).all()

        resultado = []
        for m in medicamentos:
            es_alerta = m.cantidad_restante is not None and m.cantidad_restante <= (m.umbral_alerta or 5)
            resultado.append({
                "id": m.id,
                "usuario_id": m.usuario_id,
                "tratamiento_id": m.tratamiento_id,
                "nombre": m.nombre,
                "miligramos": m.miligramos,
                "notas": m.notas,
                "frecuencia": m.frecuencia,
                "hora_alarma": m.hora_alarma.strftime("%H:%M") if m.hora_alarma else None,
                "esta_tomado": bool(m.esta_tomado),
                "cantidad_restante": m.cantidad_restante,
                "umbral_alerta": m.umbral_alerta,
                "alerta_inventario": es_alerta,
                "icono": m.icono or "💊",
                "dias_autonomia": m.dias_autonomia,
                "tomas_por_dia": m.tomas_por_dia,
                "fecha_inicio": m.fecha_inicio.isoformat() if m.fecha_inicio else None,
            })
        return resultado

    @staticmethod
    def reabastecer_medicamento_paciente(
        cuidador_id: int,
        paciente_id: int,
        med_id: int,
        cantidad: int
    ) -> Dict[str, Any]:
        """
        Permite a un cuidador reabastecer pastillas al botiquín de un paciente supervisado.

        :param cuidador_id: ID del usuario cuidador.
        :param paciente_id: ID del paciente.
        :param med_id: ID del medicamento a reabastecer.
        :param cantidad: Número de pastillas a sumar.
        :return: Diccionario con el medicamento actualizado y mensaje de éxito.
        :raises PermissionError: Si el cuidador no está vinculado al paciente.
        :raises ValueError: Si el medicamento no existe o la cantidad es inválida.
        """
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            raise PermissionError("No tienes autorización para reabastecer el botiquín de este paciente.")

        if cantidad <= 0:
            raise ValueError("La cantidad a reabastecer debe ser mayor a 0.")

        med = Medicamento.query.filter_by(id=med_id, usuario_id=paciente_id).first()
        if not med:
            raise ValueError("El medicamento no existe o no pertenece al paciente.")

        if med.cantidad_restante is None:
            med.cantidad_restante = 0

        med.cantidad_restante += cantidad
        db.session.commit()

        es_alerta = med.cantidad_restante <= (med.umbral_alerta or 5)
        return {
            "mensaje": f"Se reabastecieron {cantidad} pastillas de {med.nombre}.",
            "medicamento": {
                "id": med.id,
                "usuario_id": med.usuario_id,
                "nombre": med.nombre,
                "miligramos": med.miligramos,
                "cantidad_restante": med.cantidad_restante,
                "umbral_alerta": med.umbral_alerta,
                "alerta_inventario": es_alerta,
                "dias_autonomia": med.dias_autonomia,
                "icono": med.icono or "💊"
            }
        }

    @staticmethod
    def get_tratamientos_paciente(cuidador_id: int, paciente_id: int) -> List[Dict[str, Any]]:
        """
        Obtiene la lista de tratamientos médicos del paciente supervisado con medicamentos anidados.

        :param cuidador_id: ID del cuidador autenticado.
        :param paciente_id: ID del paciente supervisado.
        :return: Lista de tratamientos con medicamentos y posología.
        :raises PermissionError: Si el cuidador no está vinculado al paciente.
        """
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            raise PermissionError("No tienes autorización para consultar los tratamientos de este paciente.")

        tratamientos = Tratamiento.query.filter_by(usuario_id=paciente_id).order_by(Tratamiento.id.desc()).all()
        resultado = []
        for t in tratamientos:
            t_data = t.to_dict()
            t_data["medicamentos"] = [
                {
                    "id": m.id,
                    "nombre": m.nombre,
                    "miligramos": m.miligramos,
                    "frecuencia": m.frecuencia,
                    "hora_alarma": m.hora_alarma.strftime("%H:%M") if m.hora_alarma else "08:00",
                    "esta_tomado": bool(m.esta_tomado),
                    "cantidad_restante": m.cantidad_restante,
                    "dias_autonomia": m.dias_autonomia,
                    "icono": m.icono or "💊"
                }
                for m in t.medicamentos
            ]
            resultado.append(t_data)
        return resultado

    @staticmethod
    def crear_tratamiento_paciente(cuidador_id: int, paciente_id: int, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Permite al cuidador registrar un tratamiento clínico para su paciente supervisado.

        :param cuidador_id: ID del cuidador autenticado.
        :param paciente_id: ID del paciente supervisado.
        :param data: Datos del tratamiento a crear.
        :return: Diccionario del tratamiento creado.
        :raises PermissionError: Si no existe vínculo de supervisión.
        """
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            raise PermissionError("No tienes autorización para registrar tratamientos a este paciente.")

        tratamiento = TratamientoService.create(data, usuario_id=paciente_id)
        return tratamiento.to_dict()

    @staticmethod
    def actualizar_tratamiento_paciente(cuidador_id: int, paciente_id: int, tratamiento_id: int, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Permite al cuidador actualizar un tratamiento clínico existente de su paciente supervisado.

        :param cuidador_id: ID del cuidador autenticado.
        :param paciente_id: ID del paciente supervisado.
        :param tratamiento_id: ID del tratamiento a modificar.
        :param data: Datos a actualizar.
        :return: Diccionario del tratamiento actualizado.
        :raises PermissionError: Si no existe vínculo de supervisión.
        :raises ValueError: Si el tratamiento no existe.
        """
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            raise PermissionError("No tienes autorización para modificar tratamientos de este paciente.")

        tratamiento = TratamientoService.update(tratamiento_id, data, usuario_id=paciente_id)
        if not tratamiento:
            raise ValueError("Tratamiento no encontrado.")
        return tratamiento.to_dict()
