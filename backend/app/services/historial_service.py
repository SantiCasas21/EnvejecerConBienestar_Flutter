"""Servicio de Historial de Tomas y Hábitos de Bienestar."""
from typing import List, Dict, Any, Optional
from datetime import date, datetime, timedelta, timezone
from sqlalchemy import func
from app.extensions import db
from app.models.historial_toma import HistorialToma
from app.models.medicamento import Medicamento
from app.models.habito import Habito
from app.models.cuidador_paciente import CuidadorPaciente

class HistorialService:
    """Lógica de negocio para persistencia y análisis de adherencia histórica."""

    @staticmethod
    def _verificar_acceso(usuario_id: int, paciente_id: Optional[int]) -> int:
        """
        Determina y valida el ID del usuario objetivo.
        Si se pasa paciente_id, comprueba que el usuario_id tenga vínculo de cuidador activo.
        """
        if paciente_id is None or paciente_id == usuario_id:
            return usuario_id

        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=usuario_id,
            paciente_id=paciente_id
        ).first()

        if not vinculo:
            raise PermissionError("No tienes autorización para consultar el historial de este paciente.")

        return paciente_id

    @staticmethod
    def registrar_toma(
        usuario_id: int,
        medicamento_id: int,
        fecha: Optional[date] = None,
        hora_programada: Optional[str] = None,
        estado: str = 'tomada',
        notas: Optional[str] = None,
        paciente_id: Optional[int] = None,
    ) -> HistorialToma:
        """
        Registra o actualiza el estado de una toma específica de medicamento.
        """
        target_uid = HistorialService._verificar_acceso(usuario_id, paciente_id)

        medicamento = Medicamento.query.filter_by(id=medicamento_id, usuario_id=target_uid).first()
        if not medicamento:
            raise LookupError(f"Medicamento con id {medicamento_id} no encontrado para este usuario.")

        if isinstance(fecha, str):
            try:
                fecha = datetime.strptime(fecha, '%Y-%m-%d').date()
            except ValueError:
                fecha = date.today()

        fecha_toma = fecha or date.today()
        hora_prog = hora_programada
        if not hora_prog:
            if medicamento.hora_alarma:
                hora_prog = medicamento.hora_alarma.strftime('%H:%M')
            else:
                hora_prog = '08:00'

        # Buscar si ya existe un registro para esta toma específica hoy
        registro = HistorialToma.query.filter_by(
            usuario_id=target_uid,
            medicamento_id=medicamento_id,
            fecha=fecha_toma,
            hora_programada=hora_prog,
        ).first()

        if registro:
            registro.estado = estado
            registro.hora_real = datetime.now(timezone.utc)
            if notas:
                registro.notas = notas
        else:
            registro = HistorialToma(
                usuario_id=target_uid,
                medicamento_id=medicamento_id,
                fecha=fecha_toma,
                hora_programada=hora_prog,
                hora_real=datetime.now(timezone.utc),
                estado=estado,
                notas=notas,
            )
            db.session.add(registro)

        # Actualizar esta_tomado del medicamento si es fecha de hoy
        if fecha_toma == date.today():
            if estado == 'tomada':
                medicamento.esta_tomado = True
            elif estado in ('omitida', 'pospuesta'):
                # Verificar si quedan otras tomas registradas como tomadas hoy
                otras_tomadas = HistorialToma.query.filter_by(
                    usuario_id=target_uid,
                    medicamento_id=medicamento_id,
                    fecha=fecha_toma,
                    estado='tomada'
                ).filter(HistorialToma.id != (registro.id or 0)).count()
                if otras_tomadas == 0:
                    medicamento.esta_tomado = False

        db.session.commit()
        return registro

    @staticmethod
    def eliminar_toma_hoy(usuario_id: int, medicamento_id: int) -> None:
        """Elimina o revierte el registro de toma de hoy al desmarcar medicamento."""
        target_uid = usuario_id
        hoy = date.today()
        toma_hoy = HistorialToma.query.filter_by(
            usuario_id=target_uid,
            medicamento_id=medicamento_id,
            fecha=hoy,
            estado='tomada'
        ).order_by(HistorialToma.id.desc()).first()

        if toma_hoy:
            db.session.delete(toma_hoy)
            db.session.commit()

    @staticmethod
    def obtener_historial(
        usuario_id: int,
        fecha_inicio: Optional[date] = None,
        fecha_fin: Optional[date] = None,
        medicamento_id: Optional[int] = None,
        paciente_id: Optional[int] = None,
    ) -> List[HistorialToma]:
        """Obtiene la lista cronológica de tomas con filtros opcionales."""
        target_uid = HistorialService._verificar_acceso(usuario_id, paciente_id)

        query = HistorialToma.query.filter_by(usuario_id=target_uid)

        if fecha_inicio:
            query = query.filter(HistorialToma.fecha >= fecha_inicio)
        if fecha_fin:
            query = query.filter(HistorialToma.fecha <= fecha_fin)
        if medicamento_id:
            query = query.filter_by(medicamento_id=medicamento_id)

        return query.order_by(HistorialToma.fecha.desc(), HistorialToma.hora_programada.desc()).all()

    @staticmethod
    def obtener_resumen_adherencia(
        usuario_id: int,
        fecha_inicio: Optional[date] = None,
        fecha_fin: Optional[date] = None,
        paciente_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Calcula el porcentaje de adherencia global, por día y por medicamento en el rango dado.
        """
        target_uid = HistorialService._verificar_acceso(usuario_id, paciente_id)

        hoy = date.today()
        f_fin = fecha_fin or hoy
        f_inicio = fecha_inicio or (f_fin - timedelta(days=6))

        # Medicamentos activos del usuario
        medicamentos = Medicamento.query.filter_by(usuario_id=target_uid).all()

        # Tomas registradas en el rango
        tomas = HistorialToma.query.filter(
            HistorialToma.usuario_id == target_uid,
            HistorialToma.fecha >= f_inicio,
            HistorialToma.fecha <= f_fin
        ).all()

        total_tomadas = sum(1 for t in tomas if t.estado == 'tomada')
        total_pospuestas = sum(1 for t in tomas if t.estado == 'pospuesta')
        total_omitidas = sum(1 for t in tomas if t.estado == 'omitida')

        # Calcular tomas diarias esperadas de acuerdo a la frecuencia de los medicamentos
        tomas_por_dia_esperadas = sum(m.tomas_por_dia for m in medicamentos)
        num_dias = max(1, (f_fin - f_inicio).days + 1)
        total_esperadas = max(len(tomas), tomas_por_dia_esperadas * num_dias)

        porcentaje_global = 0.0
        if total_esperadas > 0:
            porcentaje_global = min(100.0, round((total_tomadas / total_esperadas) * 100, 1))

        # Desglose diario
        cumplimiento_diario = []
        cur_date = f_inicio
        while cur_date <= f_fin:
            tomas_del_dia = [t for t in tomas if t.fecha == cur_date]
            tomadas_dia = sum(1 for t in tomas_del_dia if t.estado == 'tomada')
            esperadas_dia = max(len(tomas_del_dia), tomas_por_dia_esperadas)
            pct_dia = round((tomadas_dia / esperadas_dia) * 100, 1) if esperadas_dia > 0 else 0.0

            cumplimiento_diario.append({
                "fecha": cur_date.isoformat(),
                "dia_semana": cur_date.strftime('%A'),
                "esperadas": esperadas_dia,
                "tomadas": tomadas_dia,
                "pospuestas": sum(1 for t in tomas_del_dia if t.estado == 'pospuesta'),
                "omitidas": sum(1 for t in tomas_del_dia if t.estado == 'omitida'),
                "porcentaje": pct_dia,
            })
            cur_date += timedelta(days=1)

        # Desglose por medicamento
        medicamentos_adherencia = []
        for med in medicamentos:
            tomas_med = [t for t in tomas if t.medicamento_id == med.id]
            tomadas_m = sum(1 for t in tomas_med if t.estado == 'tomada')
            esperadas_m = max(len(tomas_med), med.tomas_por_dia * num_dias)
            pct_m = round((tomadas_m / esperadas_m) * 100, 1) if esperadas_m > 0 else 0.0

            medicamentos_adherencia.append({
                "medicamento_id": med.id,
                "nombre": med.nombre,
                "icono": med.icono,
                "miligramos": med.miligramos,
                "color_icono": getattr(med, 'color_icono', '#0D9488') or '#0D9488',
                "tomadas": tomadas_m,
                "esperadas": esperadas_m,
                "porcentaje": pct_m,
                "cantidad_restante": med.cantidad_restante,
                "nivel_stock": getattr(med, 'nivel_stock', 'alerta' if getattr(med, 'alerta_inventario', False) else 'normal'),
            })

        return {
            "usuario_id": target_uid,
            "fecha_inicio": f_inicio.isoformat(),
            "fecha_fin": f_fin.isoformat(),
            "total_esperadas": total_esperadas,
            "total_tomadas": total_tomadas,
            "total_pospuestas": total_pospuestas,
            "total_omitidas": total_omitidas,
            "porcentaje_adherencia_global": porcentaje_global,
            "cumplimiento_diario": cumplimiento_diario,
            "medicamentos_adherencia": medicamentos_adherencia,
        }

    @staticmethod
    def obtener_historial_habitos(
        usuario_id: int,
        fecha_inicio: Optional[date] = None,
        fecha_fin: Optional[date] = None,
        tipo: Optional[str] = None,
        paciente_id: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Obtiene el historial de progreso de hábitos (agua, caminata, sueño, etc.).
        """
        target_uid = HistorialService._verificar_acceso(usuario_id, paciente_id)

        query = Habito.query.filter_by(usuario_id=target_uid)

        if fecha_inicio:
            query = query.filter(Habito.fecha >= fecha_inicio)
        if fecha_fin:
            query = query.filter(Habito.fecha <= fecha_fin)
        if tipo:
            query = query.filter(func.lower(Habito.tipo) == tipo.lower().strip())

        habitos = query.order_by(Habito.fecha.desc(), Habito.id.desc()).all()

        resultado = []
        for h in habitos:
            resultado.append({
                "id": h.id,
                "tipo": h.tipo,
                "meta": h.meta,
                "progreso_actual": h.progreso_actual,
                "porcentaje": round(h.porcentaje, 1),
                "fecha": h.fecha.isoformat(),
                "cumplido": h.progreso_actual >= h.meta,
            })

        return resultado
