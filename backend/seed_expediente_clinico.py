"""
Script de siembra (seed) para la Ficha Médica Integral y Tratamientos Clínicos Estructurados.
Puebla el expediente clínico completo para el usuario de prueba: prueba@envejecer.com
"""
import sys
try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

from datetime import date, datetime, timezone
from app import create_app
from app.extensions import db
from app.models.usuario import Usuario
from app.models.perfil import PerfilUsuario
from app.models.tratamiento import Tratamiento
from app.models.medicamento import Medicamento

def poblar_expediente_clinico(app=None):
    from flask import has_app_context
    if has_app_context():
        return _ejecutar_poblamiento_expediente()

    if app is None:
        app = create_app()
    with app.app_context():
        return _ejecutar_poblamiento_expediente()

def _ejecutar_poblamiento_expediente():
    print("=" * 70)
    print("🏥 [SEED] INICIANDO POBLAMIENTO DE FICHA MÉDICA Y TRATAMIENTOS")
    print("=" * 70)

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

    # 2. Configurar Perfil y Ficha Médica Integral
    perfil = PerfilUsuario.query.filter_by(usuario_id=usuario.id).first()
    if not perfil:
        perfil = PerfilUsuario(usuario_id=usuario.id)
        db.session.add(perfil)

    perfil.tipo_documento = 'CC'
    perfil.numero_documento = '41.876.543'
    perfil.fecha_nacimiento = '1948-11-20'
    perfil.edad = 77
    perfil.genero = 'Femenino'
    perfil.tipo_sangre = 'A+'
    perfil.peso = 62.0
    perfil.altura = 158.0
    perfil.presion_habitual = '120/75 mmHg'
    perfil.nivel_movilidad = 'Independiente con apoyo ligero'
    perfil.eps = 'Sanitas EPS'
    perfil.regimen_eps = 'Contributivo'
    perfil.alergias = 'Penicilina, AINEs derivados de ácido acetilsalicílico'
    perfil.condiciones = 'Hipertensión Arterial Primaria, Diabetes Mellitus Tipo 2, Artrosis de Rodilla Bilateral leve'
    perfil.cirugias = 'Apendicectomía (1985), Colecistectomía laparoscópica (2012)'
    perfil.dispositivos_medicos = 'Gafas bifocales, tensiómetro digital casero'
    perfil.restricciones_alimentarias = 'Bajo contenido en sodio, control de carbohidratos simples'
    perfil.antecedentes_familiares = 'Madre con Diabetes Mellitus Tipo 2, Padre con enfermedad coronaria'
    perfil.telefono = '3157894561'
    perfil.contacto_emergencia_nombre = 'Andrés Pérez'
    perfil.contacto_emergencia_telefono = '3104567890'
    perfil.contacto_emergencia_parentesco = 'Hijo'
    perfil.medico_tratante = 'Dra. Claudia Ortiz'
    perfil.telefono_medico = '6015678901'
    perfil.clinica_preferida = 'Clínica Colombia'
    perfil.acepto_habeas_data = True
    perfil.fecha_habeas_data = datetime(2026, 8, 20, 10, 0, tzinfo=timezone.utc)
    perfil.notas_adicionales = 'Paciente muy comprometida con su autocuidado y registro diario.'
    db.session.flush()
    print("✅ Perfil y Ficha Médica Integral actualizados exitosamente.")

    # 3. Tratamientos Clínicos Estructurados
    tratamientos_config = [
        {
            'clave': 'hta',
            'diagnostico': 'Hipertensión Arterial Primaria (CIE-10: I10)',
            'medico_tratante': 'Dra. Claudia Ortiz',
            'especialidad_medica': 'Medicina Interna',
            'institucion_salud': 'Sanitas EPS / Clínica Colombia',
            'fecha_inicio': date(2026, 8, 20),
            'fecha_fin': None,
            'es_cronico': True,
            'estado': 'activo',
            'color': '#1E3A8A',
            'objetivo_terapeutico': 'Mantener PA < 130/80 mmHg',
            'notas_evolucion': 'Paciente asintomática, cifras tensionales estables y bien controladas.',
            'recomendaciones': 'Monitoreo de presión 2 veces por semana. Mantener dieta baja en sodio.',
            'fecha_ultima_revision': date(2026, 9, 15),
            'proxima_cita': date(2026, 12, 10),
            'instrucciones': 'Tomar Losartán 50mg cada mañana con abundante agua.',
            'medicamento_nombre': 'Losartán 50mg'
        },
        {
            'clave': 'dm2',
            'diagnostico': 'Diabetes Mellitus Tipo 2 (CIE-10: E11)',
            'medico_tratante': 'Dr. Gabriel Valencia',
            'especialidad_medica': 'Endocrinología',
            'institucion_salud': 'Sanitas Tequendama',
            'fecha_inicio': date(2026, 8, 20),
            'fecha_fin': None,
            'es_cronico': True,
            'estado': 'activo',
            'color': '#0D9488',
            'objetivo_terapeutico': 'HbA1c < 7.0%, glucemia 80-120 mg/dL',
            'notas_evolucion': 'Glucemias basales dentro de rangos meta con Metformina. Buena tolerancia digestiva.',
            'recomendaciones': 'Caminata diaria de al menos 30 minutos y control riguroso de carbohidratos simples.',
            'fecha_ultima_revision': date(2026, 8, 25),
            'proxima_cita': date(2026, 11, 25),
            'instrucciones': 'Metformina 850mg dos veces al día junto con las comidas principales.',
            'medicamento_nombre': 'Metformina 850mg'
        },
        {
            'clave': 'artrosis',
            'diagnostico': 'Artrosis de Rodilla Bilateral (CIE-10: M17)',
            'medico_tratante': 'Dr. Roberto Gómez',
            'especialidad_medica': 'Ortopedia y Reumatología',
            'institucion_salud': 'Hospital Méderi',
            'fecha_inicio': date(2026, 8, 20),
            'fecha_fin': date(2027, 2, 20), # 6 meses de manejo agudo
            'es_cronico': False,
            'estado': 'activo',
            'color': '#059669',
            'objetivo_terapeutico': 'Control del dolor matutino y fortalecimiento articular',
            'notas_evolucion': 'Buena respuesta analgésica con Acetaminofén y ejercicios guiados de estiramiento.',
            'recomendaciones': 'Pausas activas y estiramientos suaves diarios de cuádriceps e isquiotibiales.',
            'fecha_ultima_revision': date(2026, 9, 20),
            'proxima_cita': date(2026, 11, 12),
            'instrucciones': 'Acetaminofén 500mg cada 8 horas con agua en caso de molestia o rigidez.',
            'medicamento_nombre': 'Acetaminofén 500mg'
        }
    ]

    tratamientos_creados = []
    for t_data in tratamientos_config:
        # Buscar por diagnóstico o crear
        t = Tratamiento.query.filter(
            Tratamiento.usuario_id == usuario.id,
            Tratamiento.diagnostico.like(f"%{t_data['clave']}%") | Tratamiento.diagnostico.like(f"{t_data['diagnostico'][:20]}%")
        ).first()

        if not t:
            t = Tratamiento(
                usuario_id=usuario.id,
                diagnostico=t_data['diagnostico'],
                medico_tratante=t_data['medico_tratante'],
                especialidad_medica=t_data['especialidad_medica'],
                institucion_salud=t_data['institucion_salud'],
                fecha_inicio=t_data['fecha_inicio'],
                fecha_fin=t_data['fecha_fin'],
                es_cronico=t_data['es_cronico'],
                estado=t_data['estado'],
                color=t_data['color'],
                objetivo_terapeutico=t_data['objetivo_terapeutico'],
                notas_evolucion=t_data['notas_evolucion'],
                recomendaciones=t_data['recomendaciones'],
                fecha_ultima_revision=t_data['fecha_ultima_revision'],
                proxima_cita=t_data['proxima_cita'],
                instrucciones=t_data['instrucciones']
            )
            db.session.add(t)
            db.session.flush()
            print(f"✨ Creado tratamiento: {t.diagnostico} (ID: {t.id})")
        else:
            t.diagnostico = t_data['diagnostico']
            t.medico_tratante = t_data['medico_tratante']
            t.especialidad_medica = t_data['especialidad_medica']
            t.institucion_salud = t_data['institucion_salud']
            t.fecha_inicio = t_data['fecha_inicio']
            t.fecha_fin = t_data['fecha_fin']
            t.es_cronico = t_data['es_cronico']
            t.estado = t_data['estado']
            t.color = t_data['color']
            t.objetivo_terapeutico = t_data['objetivo_terapeutico']
            t.notas_evolucion = t_data['notas_evolucion']
            t.recomendaciones = t_data['recomendaciones']
            t.fecha_ultima_revision = t_data['fecha_ultima_revision']
            t.proxima_cita = t_data['proxima_cita']
            t.instrucciones = t_data['instrucciones']
            db.session.flush()
            print(f"🔄 Actualizado tratamiento: {t.diagnostico} (ID: {t.id})")

        # Vincular con el medicamento correspondiente
        med = Medicamento.query.filter(
            Medicamento.usuario_id == usuario.id,
            Medicamento.nombre.ilike(f"%{t_data['medicamento_nombre'][:10]}%")
        ).first()

        if med:
            med.tratamiento_id = t.id
            db.session.flush()
            print(f"  🔗 Medicamento '{med.nombre}' vinculado al Tratamiento ID {t.id}")
        else:
            print(f"  ⚠️ Medicamento '{t_data['medicamento_nombre']}' no encontrado para vincular.")

        tratamientos_creados.append(t)

    db.session.commit()

    print("=" * 70)
    print("🎉 [EXPEDIENTE CLÍNICO COMPLETADO CON ÉXITO]")
    print(f"👤 Usuario: {usuario.nombre} ({usuario.email})")
    print(f"📋 Ficha Médica: CC {perfil.numero_documento}, {perfil.edad} años, Sangre {perfil.tipo_sangre}, EPS {perfil.eps}")
    print(f"🩺 Tratamientos Activos: {len(tratamientos_creados)}")
    for tr in tratamientos_creados:
        meds_nombres = [m.nombre for m in tr.medicamentos]
        print(f"   • {tr.diagnostico} | Médico: {tr.medico_tratante} | Meds: {', '.join(meds_nombres) or 'Ninguno'}")
    print("=" * 70)

    return {
        'usuario_id': usuario.id,
        'perfil_id': perfil.id,
        'tratamientos_count': len(tratamientos_creados),
        'status': 'completado'
    }

if __name__ == '__main__':
    poblar_expediente_clinico()
