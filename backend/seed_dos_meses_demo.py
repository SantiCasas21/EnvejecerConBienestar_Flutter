"""
Script de generación de datos realistas (2 meses continuos) para usuario de prueba.
Puebla desde el 29 de Agosto de 2026 hasta el 28 de Octubre de 2026 (61 días).
Usuario objetivo: prueba@envejecer.com
"""
import sys
try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

import random
from datetime import date, datetime, time, timedelta, timezone
from app import create_app
from app.extensions import db
from app.models.usuario import Usuario
from app.models.perfil import PerfilUsuario
from app.models.medicamento import Medicamento
from app.models.meta import Meta
from app.models.habito import Habito
from app.models.historial_toma import HistorialToma

def poblar_dos_meses_demo(app=None):
    from flask import has_app_context
    if has_app_context():
        return _ejecutar_poblamiento()

    if app is None:
        app = create_app()
    with app.app_context():
        return _ejecutar_poblamiento()

def _ejecutar_poblamiento():
    print("=" * 65)
    print("🌱 [SEED] INICIANDO POBLAMIENTO DE 2 MESES PARA PRUEBA@ENVEJECER.COM")
    print("=" * 65)

    # 1. Obtener o crear usuario prueba@envejecer.com
    usuario = Usuario.query.filter_by(email='prueba@envejecer.com').first()
    if not usuario:
        usuario = Usuario(
            nombre='Adulto Mayor Demo',
            email='prueba@envejecer.com',
            rol='adulto_mayor',
            codigo_vinculacion='ECB-1002'
        )
        usuario.set_password('password123')
        db.session.add(usuario)
        db.session.flush()
        print(f"✅ Usuario creado con ID: {usuario.id}")
    else:
        print(f"ℹ️ Usuario existente encontrado con ID: {usuario.id}")

    # Perfil asegurado
    perfil = PerfilUsuario.query.filter_by(usuario_id=usuario.id).first()
    if not perfil:
        perfil = PerfilUsuario(
            usuario_id=usuario.id,
            tipo_documento='CC',
            numero_documento='41.876.543',
            fecha_nacimiento='1948-11-20',
            edad=77,
            genero='Femenino',
            tipo_sangre='A+',
            peso=62.0,
            altura=158.0,
            eps='Sanitas EPS',
            regimen_eps='Contributivo',
            presion_habitual='120/75 mmHg',
            nivel_movilidad='Independiente',
            alergias='Ninguna conocida',
            condiciones='Hipertensión leve, Diabetes Tipo 2 controlada',
            telefono='3157894561',
            contacto_emergencia_nombre='Andrés Pérez',
            contacto_emergencia_telefono='3104567890',
            contacto_emergencia_parentesco='Hijo',
            medico_tratante='Dra. Claudia Ortiz (Internista)',
            telefono_medico='6015678901',
            clinica_preferida='Clínica Colombia'
        )
        db.session.add(perfil)
    db.session.flush()

    # 2. Medicamentos configurados
    meds_config = [
        {
            'nombre': 'Acetaminofén 500mg',
            'miligramos': '500 mg',
            'frecuencia': 8,
            'hora_alarma': time(8, 0),
            'tomas_diarias': ['08:00', '14:00', '20:00'],
            'cantidad_restante': 30,
            'umbral_alerta': 5,
            'icono': '💊',
            'notas': '1 pastilla cada 8 horas para alivio de dolor articular',
        },
        {
            'nombre': 'Losartán 50mg',
            'miligramos': '50 mg',
            'frecuencia': 24,
            'hora_alarma': time(8, 0),
            'tomas_diarias': ['08:00'],
            'cantidad_restante': 28,
            'umbral_alerta': 5,
            'icono': '💊',
            'notas': '1 pastilla diaria en la mañana para control de presión arterial',
        },
        {
            'nombre': 'Metformina 850mg',
            'miligramos': '850 mg',
            'frecuencia': 12,
            'hora_alarma': time(8, 30),
            'tomas_diarias': ['08:30', '20:30'],
            'cantidad_restante': 25,
            'umbral_alerta': 5,
            'icono': '💊',
            'notas': '1 pastilla cada 12 horas con las comidas principales',
        },
        {
            'nombre': 'Atorvastatina 20mg',
            'miligramos': '20 mg',
            'frecuencia': 24,
            'hora_alarma': time(21, 0),
            'tomas_diarias': ['21:00'],
            'cantidad_restante': 20,
            'umbral_alerta': 5,
            'icono': '💊',
            'notas': '1 pastilla en la noche para control de colesterol',
        },
    ]

    medicamentos_creados = []
    for m_data in meds_config:
        m = Medicamento.query.filter_by(usuario_id=usuario.id, nombre=m_data['nombre']).first()
        if not m:
            m = Medicamento(
                usuario_id=usuario.id,
                nombre=m_data['nombre'],
                miligramos=m_data['miligramos'],
                frecuencia=m_data['frecuencia'],
                hora_alarma=m_data['hora_alarma'],
                cantidad_restante=m_data['cantidad_restante'],
                umbral_alerta=m_data['umbral_alerta'],
                icono=m_data['icono'],
                notas=m_data['notas'],
                fecha_inicio=date(2026, 8, 20),
                esta_tomado=True
            )
            db.session.add(m)
            db.session.flush()
        else:
            m.miligramos = m_data['miligramos']
            m.frecuencia = m_data['frecuencia']
            m.hora_alarma = m_data['hora_alarma']
            m.cantidad_restante = m_data['cantidad_restante']
            m.umbral_alerta = m_data['umbral_alerta']
            m.notas = m_data['notas']
            m.esta_tomado = True
        medicamentos_creados.append((m, m_data['tomas_diarias']))

    print(f"✅ {len(medicamentos_creados)} medicamentos configurados.")

    # 3. Metas activas aseguradas
    metas_config = [
        {'nombre': 'Tomar agua', 'objetivo': 8, 'unidad': 'vasos', 'icono': '💧'},
        {'nombre': 'Caminata y paseo', 'objetivo': 30, 'unidad': 'minutos', 'icono': '🚶'},
        {'nombre': 'Estiramientos suaves', 'objetivo': 15, 'unidad': 'minutos', 'icono': '🧘'},
        {'nombre': 'Sueño reparador', 'objetivo': 8, 'unidad': 'horas', 'icono': '😴'},
        {'nombre': 'Gimnasio mental', 'objetivo': 1, 'unidad': 'sesión', 'icono': '🧠'},
    ]

    for meta_data in metas_config:
        meta = Meta.query.filter_by(usuario_id=usuario.id, nombre=meta_data['nombre']).first()
        if not meta:
            meta = Meta(
                usuario_id=usuario.id,
                nombre=meta_data['nombre'],
                objetivo=meta_data['objetivo'],
                unidad=meta_data['unidad'],
                icono=meta_data['icono'],
                progreso=meta_data['objetivo'],
                completada=True,
                fecha_inicio=date(2026, 8, 20)
            )
            db.session.add(meta)
        else:
            meta.objetivo = meta_data['objetivo']
            meta.progreso = meta_data['objetivo']
            meta.completada = True

    db.session.flush()
    print("✅ 5 metas de bienestar configuradas.")

    # 4. Limpiar registros previos en el rango de los 2 meses para idempotencia
    fecha_fin_rango = max(date.today(), date(2026, 10, 29))
    fecha_inicio_rango = fecha_fin_rango - timedelta(days=61)

    deleted_tomas = HistorialToma.query.filter(
        HistorialToma.usuario_id == usuario.id,
        HistorialToma.fecha >= fecha_inicio_rango,
        HistorialToma.fecha <= fecha_fin_rango
    ).delete()

    deleted_habitos = Habito.query.filter(
        Habito.usuario_id == usuario.id,
        Habito.fecha >= fecha_inicio_rango,
        Habito.fecha <= fecha_fin_rango
    ).delete()

    print(f"🧹 Registros previos eliminados: {deleted_tomas} tomas, {deleted_habitos} hábitos.")

    # 5. Generación de 61 días continuos de Tomas y Hábitos
    random.seed(42)  # Semilla determinista para coherencia
    cur_date = fecha_inicio_rango
    total_tomas_insertadas = 0
    total_habitos_insertados = 0
    tomadas_count = 0
    esperadas_count = 0

    notas_cumplidas = [
        "Tomada con abundante agua",
        "Tomada después del desayuno",
        "Tomada con el almuerzo",
        "Tomada con la cena",
        "Sin efectos secundarios, excelente sensación",
        "Tomada puntual a la hora de alarma",
    ]

    while cur_date <= fecha_fin_rango:
        es_hoy = (cur_date == fecha_fin_rango)

        # --- A. Generar Tomas de Medicamentos del Día ---
        for med, horas_toma in medicamentos_creados:
            for hora_prog in horas_toma:
                esperadas_count += 1
                hora_p_parts = [int(p) for p in hora_prog.split(':')]
                h_int, m_int = hora_p_parts[0], hora_p_parts[1]

                # Determinar estado: hoy en la mañana siempre 100% tomada
                if es_hoy and h_int <= 12:
                    estado = 'tomada'
                    min_desvio = random.randint(0, 8)
                    hora_real_val = datetime.combine(cur_date, time(h_int, min(59, m_int + min_desvio)), tzinfo=timezone.utc)
                    nota = "Tomada a tiempo esta mañana"
                elif es_hoy and h_int > 12:
                    estado = 'tomada'
                    hora_real_val = datetime.combine(cur_date, time(h_int, m_int), tzinfo=timezone.utc)
                    nota = "Registrada en horario habitual"
                else:
                    # Días anteriores: 88% tomada, 7% pospuesta, 5% omitida
                    rand_val = random.random()
                    if rand_val < 0.88:
                        estado = 'tomada'
                        min_desvio = random.randint(-5, 20)
                        safe_m = max(0, min(59, m_int + min_desvio))
                        hora_real_val = datetime.combine(cur_date, time(h_int, safe_m), tzinfo=timezone.utc)
                        nota = random.choice(notas_cumplidas)
                    elif rand_val < 0.95:
                        estado = 'pospuesta'
                        hora_real_val = datetime.combine(cur_date, time(min(23, h_int + 1), m_int), tzinfo=timezone.utc)
                        nota = "Pospuesta 1 hora por salida médica"
                    else:
                        estado = 'omitida'
                        hora_real_val = None
                        nota = "Omitida por indicación de ayuno para exámenes"

                if estado == 'tomada':
                    tomadas_count += 1

                reg_toma = HistorialToma(
                    usuario_id=usuario.id,
                    medicamento_id=med.id,
                    fecha=cur_date,
                    hora_programada=hora_prog,
                    hora_real=hora_real_val,
                    estado=estado,
                    notas=nota
                )
                db.session.add(reg_toma)
                total_tomas_insertadas += 1

        # --- B. Generar Hábitos del Día ---
        habitos_dia = [
            ('agua', 8, 8 if random.random() < 0.85 else 7),
            ('caminata', 30, 30 if random.random() < 0.82 else 25),
            ('estiramientos', 15, 15 if random.random() < 0.88 else 10),
            ('sueño', 8, 8 if random.random() < 0.80 else 7),
            ('mente', 1, 1),
        ]

        for tipo_h, meta_h, prog_h in habitos_dia:
            habito_rec = Habito(
                usuario_id=usuario.id,
                tipo=tipo_h,
                meta=meta_h,
                progreso_actual=prog_h,
                fecha=cur_date
            )
            db.session.add(habito_rec)
            total_habitos_insertados += 1

        cur_date += timedelta(days=1)

    db.session.commit()

    adherencia_pct = round((tomadas_count / max(1, esperadas_count)) * 100, 1)

    print("=" * 65)
    print("🎉 [SEED COMPLETADO CON ÉXITO]")
    print(f"📅 Rango de fechas: {fecha_inicio_rango} a {fecha_fin_rango} (61 días)")
    print(f"💊 Total tomas insertadas: {total_tomas_insertadas} ({tomadas_count} tomadas, {adherencia_pct}% adherencia global)")
    print(f"🌱 Total hábitos diarios insertados: {total_habitos_insertados} (5 hábitos x 61 días)")
    print(f"🔥 Racha de hoy ({fecha_fin_rango}): Tomas registradas y activas.")
    print("=" * 65)

    return {
        'usuario_id': usuario.id,
        'total_tomas': total_tomas_insertadas,
        'total_habitos': total_habitos_insertados,
        'adherencia': adherencia_pct,
        'dias': 61
    }

if __name__ == '__main__':
    poblar_dos_meses_demo()
