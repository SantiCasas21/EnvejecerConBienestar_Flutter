"""Servicio de Historial de Tomas y Hábitos de Bienestar."""
from typing import List, Dict, Any, Optional
from datetime import date, datetime, timedelta, timezone
from sqlalchemy import func
from app.extensions import db
from app.models.historial_toma import HistorialToma
from app.models.medicamento import Medicamento
from app.models.habito import Habito
from app.models.meta import Meta
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
        dias: Optional[int] = None,
        paciente_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Calcula el porcentaje de adherencia global, por día y por medicamento en el rango dado.
        """
        target_uid = HistorialService._verificar_acceso(usuario_id, paciente_id)

        hoy = date.today()
        if dias and dias > 0:
            f_fin = fecha_fin or hoy
            f_inicio = f_fin - timedelta(days=dias - 1)
        else:
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

        # Desglose de hábitos en el periodo
        habitos_query = Habito.query.filter(
            Habito.usuario_id == target_uid,
            Habito.fecha >= f_inicio,
            Habito.fecha <= f_fin
        ).all()

        metas_activas = Meta.query.filter_by(usuario_id=target_uid).all()
        habitos_resumen = []

        if habitos_query:
            tipos = sorted(list({h.tipo for h in habitos_query}))
            for t in tipos:
                h_del_tipo = [h for h in habitos_query if h.tipo == t]
                cumplidos = sum(1 for h in h_del_tipo if h.progreso_actual >= h.meta and h.meta > 0)
                tot = len(h_del_tipo)
                pct = round((cumplidos / tot) * 100, 1) if tot > 0 else 0.0
                habitos_resumen.append({
                    "nombre": t.capitalize(),
                    "icono": "💧" if "agua" in t.lower() else ("🚶" if "cam" in t.lower() else ("🧘" if "estir" in t.lower() else "🌿")),
                    "cumplidos": cumplidos,
                    "total_dias": tot,
                    "porcentaje": pct,
                })
        elif metas_activas:
            for m in metas_activas:
                pct = round(m.porcentaje, 1)
                habitos_resumen.append({
                    "nombre": m.nombre,
                    "icono": m.icono,
                    "cumplidos": 1 if m.completada else 0,
                    "total_dias": 1,
                    "porcentaje": pct,
                })

        racha_data = HistorialService.calcular_racha(usuario_id=usuario_id, paciente_id=paciente_id)

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
            "resumen_habitos": habitos_resumen,
            "racha": racha_data,
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

    @staticmethod
    def calcular_racha(usuario_id: int, paciente_id: Optional[int] = None) -> Dict[str, Any]:
        """
        Calcula la racha actual de días consecutivos con actividades de salud cumplidas
        (al menos una toma tomada o al menos un hábito cumplido/progresado).
        """
        target_uid = HistorialService._verificar_acceso(usuario_id, paciente_id)
        hoy = date.today()

        # Fechas de tomas tomadas
        fechas_tomas = {
            t.fecha for t in HistorialToma.query.filter_by(
                usuario_id=target_uid,
                estado='tomada'
            ).all()
        }

        # Fechas con hábitos con progreso
        fechas_habitos = {
            h.fecha for h in Habito.query.filter(
                Habito.usuario_id == target_uid,
                Habito.progreso_actual > 0
            ).all()
        }

        fechas_activas = fechas_tomas.union(fechas_habitos)

        # Evaluar racha actual continua
        racha_actual = 0
        dia_evaluar = None
        if hoy in fechas_activas:
            dia_evaluar = hoy
        else:
            ayer = hoy - timedelta(days=1)
            if ayer in fechas_activas:
                dia_evaluar = ayer

        if dia_evaluar:
            temp = dia_evaluar
            while temp in fechas_activas:
                racha_actual += 1
                temp -= timedelta(days=1)

        # Mejor racha histórica
        fechas_ordenadas = sorted(list(fechas_activas))
        racha_mejor = 0
        racha_temp = 0
        prev_fecha = None
        for f in fechas_ordenadas:
            if prev_fecha is None or f == prev_fecha + timedelta(days=1):
                racha_temp += 1
            elif f > prev_fecha + timedelta(days=1):
                racha_temp = 1
            prev_fecha = f
            if racha_temp > racha_mejor:
                racha_mejor = racha_temp
        racha_mejor = max(racha_actual, racha_mejor)

        # Mensaje dinámico de motivación
        if racha_actual == 0:
            mensaje = "¡Enciende hoy tu llama de salud! Cumple tus tomas o un hábito para iniciar tu racha 🔥"
        elif racha_actual == 1:
            mensaje = "¡Llama encendida! Hoy diste el primer gran paso hacia tu mejor versión 🌟"
        elif racha_actual <= 3:
            mensaje = f"🔥 ¡{racha_actual} días seguidos de pura vitalidad! Tu constancia inspira."
        elif racha_actual <= 6:
            mensaje = f"🔥 ¡Racha de fuego! {racha_actual} días cuidando de ti sin descanso."
        elif racha_actual <= 13:
            mensaje = f"👑 ¡Una semana entera imparable! Tus hábitos construyen salud y alegría."
        else:
            mensaje = f"⚡ ¡Leyenda de bienestar! {racha_actual} días consecutivos. ¡Eres un ejemplo familiar!"

        # Días de la semana actual
        lunes = hoy - timedelta(days=hoy.weekday())
        dias_semana = []
        nombres_dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D']
        for i in range(7):
            f = lunes + timedelta(days=i)
            dias_semana.append({
                "letra": nombres_dias[i],
                "fecha": f.isoformat(),
                "activo": f in fechas_activas,
                "es_hoy": f == hoy,
            })

        return {
            "usuario_id": target_uid,
            "racha_actual": racha_actual,
            "racha_mejor": racha_mejor,
            "mensaje_racha": mensaje,
            "dias_semana": dias_semana,
            "hoy_completado": hoy in fechas_activas,
        }
