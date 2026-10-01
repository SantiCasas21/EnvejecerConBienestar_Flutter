"""Script de siembra (seed) para poblar usuarios y datos de prueba completos."""
from datetime import datetime, time, date
from app import create_app
from app.extensions import db
from app.models.usuario import Usuario
from app.models.perfil import PerfilUsuario
from app.models.tratamiento import Tratamiento
from app.models.medicamento import Medicamento
from app.models.meta import Meta
from app.models.contacto import Contacto
from app.models.cuidador_paciente import CuidadorPaciente

def run_seed():
    app = create_app()
    with app.app_context():
        print("[SEED] Sembrando base de datos con usuarios y datos de prueba...")

        # 1. Usuario Principal: Santiago
        u1 = Usuario.query.filter_by(email='santiago@envejecer.com').first()
        if not u1:
            u1 = Usuario(
                nombre='Santiago Gómez',
                email='santiago@envejecer.com',
                rol='adulto_mayor',
                codigo_vinculacion='ECB-1001'
            )
            u1.set_password('password123')
            db.session.add(u1)
            db.session.flush()
        u1.nombre = 'Santiago Gómez'
        u1.rol = 'adulto_mayor'
        u1.codigo_vinculacion = 'ECB-1001'
        u1.set_password('password123')

        # Perfil Médico de Santiago
        p1 = PerfilUsuario.query.filter_by(usuario_id=u1.id).first()
        if not p1:
            p1 = PerfilUsuario(usuario_id=u1.id)
            db.session.add(p1)
        p1.tipo_documento = 'CC'
        p1.numero_documento = '19.482.903'
        p1.fecha_nacimiento = '1951-05-14'
        p1.edad = 75
        p1.genero = 'Masculino'
        p1.tipo_sangre = 'O+'
        p1.peso = 68.5
        p1.altura = 165.0
        p1.eps = 'SURA EPS'
        p1.regimen_eps = 'Contributivo'
        p1.presion_habitual = '125/80 mmHg'
        p1.nivel_movilidad = 'Uso de bastón para caminatas largas'
        p1.telefono = '3109876543'
        p1.alergias = 'Penicilina, Mariscos'
        p1.condiciones = 'Hipertensión arterial controlada, Artrosis leve'
        p1.cirugias = 'Apendicectomía (1985)'
        p1.dispositivos_medicos = 'Lentes para lectura, Bastón para caminatas'
        p1.restricciones_alimentarias = 'Baja en sodio, baja en grasas saturadas'
        p1.antecedentes_familiares = 'Padre hipertenso, madre con artrosis severa'
        p1.contacto_emergencia_nombre = 'Carolina Gómez'
        p1.contacto_emergencia_telefono = '3001234567'
        p1.contacto_emergencia_parentesco = 'Hijo / Hija'
        p1.medico_tratante = 'Dr. Fernando Ramírez (Geriatra)'
        p1.telefono_medico = '6013456789'
        p1.clinica_preferida = 'Clínica Reina Sofía'
        p1.notas_adicionales = 'Tomar abundante agua con las pastillas matutinas.'

        # 2. Usuario de Prueba Alternativo
        u2 = Usuario.query.filter_by(email='prueba@envejecer.com').first()
        if not u2:
            u2 = Usuario(
                nombre='Adulto Mayor Demo',
                email='prueba@envejecer.com',
                rol='adulto_mayor',
                codigo_vinculacion='ECB-1002'
            )
            u2.set_password('password123')
            db.session.add(u2)
            db.session.flush()
        u2.nombre = 'Adulto Mayor Demo'
        u2.rol = 'adulto_mayor'
        u2.codigo_vinculacion = 'ECB-1002'
        u2.set_password('password123')

        # Perfil de Demo
        p2 = PerfilUsuario.query.filter_by(usuario_id=u2.id).first()
        if not p2:
            p2 = PerfilUsuario(usuario_id=u2.id)
            db.session.add(p2)
        p2.tipo_documento = 'CC'
        p2.numero_documento = '41.876.543'
        p2.fecha_nacimiento = '1948-11-20'
        p2.edad = 77
        p2.genero = 'Femenino'
        p2.tipo_sangre = 'A+'
        p2.peso = 62.0
        p2.altura = 158.0
        p2.eps = 'Sanitas EPS'
        p2.regimen_eps = 'Contributivo'
        p2.presion_habitual = '120/75 mmHg'
        p2.nivel_movilidad = 'Independiente'
        p2.telefono = '3201234567'
        p2.alergias = 'Ninguna'
        p2.condiciones = 'Diabetes Tipo 2'
        p2.restricciones_alimentarias = 'Sin azúcar refinada'
        p2.antecedentes_familiares = 'Madre con diabetes tipo 2'
        p2.contacto_emergencia_nombre = 'Andrés Pérez'
        p2.contacto_emergencia_telefono = '3119876543'
        p2.contacto_emergencia_parentesco = 'Cónyuge / Pareja'
        p2.medico_tratante = 'Dra. Marcela Torres'
        p2.telefono_medico = '6017654321'

        # 3. Cuidador de Prueba
        u_cuidador = Usuario.query.filter_by(email='cuidador@envejecer.com').first()
        if not u_cuidador:
            u_cuidador = Usuario(
                nombre='Carolina Gómez (Cuidadora)',
                email='cuidador@envejecer.com',
                rol='cuidador',
                codigo_vinculacion=None
            )
            u_cuidador.set_password('password123')
            db.session.add(u_cuidador)
            db.session.flush()
        u_cuidador.nombre = 'Carolina Gómez (Cuidadora)'
        u_cuidador.rol = 'cuidador'
        u_cuidador.codigo_vinculacion = None
        u_cuidador.set_password('password123')

        # Vincular cuidador con Santiago Gómez
        vinculo = CuidadorPaciente.query.filter_by(
            cuidador_id=u_cuidador.id,
            paciente_id=u1.id
        ).first()
        if not vinculo:
            vinculo = CuidadorPaciente(
                cuidador_id=u_cuidador.id,
                paciente_id=u1.id,
                parentesco='Hija / Cuidadora'
            )
            db.session.add(vinculo)
        else:
            vinculo.parentesco = 'Hija / Cuidadora'

        # 4. Tratamientos Clínicos para Usuario 1 (Santiago)
        t1 = Tratamiento.query.filter_by(usuario_id=u1.id, diagnostico='Hipertensión Arterial Primaria').first()
        if not t1:
            t1 = Tratamiento(
                usuario_id=u1.id,
                diagnostico='Hipertensión Arterial Primaria',
                especialidad_medica='Cardiología / Geriatría',
                medico_tratante='Dr. Fernando Ramírez (Geriatra)',
                institucion_salud='Clínica Reina Sofía',
                fecha_inicio=date(2024, 1, 15),
                es_cronico=True,
                estado='activo',
                objetivo_terapeutico='Mantener TA sistólica < 130 mmHg y diastólica < 80 mmHg',
                notas_evolucion='Paciente asintomático, adecuada respuesta hemodinámica. Sin edemas periféricos.',
                recomendaciones='Dieta baja en sodio (<2g/día), caminata matutina 20 min, hidratación constante.',
                fecha_ultima_revision=date(2026, 8, 10),
                proxima_cita=date(2026, 11, 20),
                instrucciones='Tomar diariamente según horario estricto.',
                color='#0D9488'
            )
            db.session.add(t1)
            db.session.flush()

        t2 = Tratamiento.query.filter_by(usuario_id=u1.id, diagnostico='Control Metabólico Preventivo').first()
        if not t2:
            t2 = Tratamiento(
                usuario_id=u1.id,
                diagnostico='Control Metabólico Preventivo',
                especialidad_medica='Medicina Interna',
                medico_tratante='Dra. Marcela Torres',
                institucion_salud='SURA EPS Sede Principal',
                fecha_inicio=date(2025, 3, 1),
                es_cronico=True,
                estado='activo',
                objetivo_terapeutico='Glucemia en ayunas < 100 mg/dL y HbA1c < 6.5%',
                notas_evolucion='Buena tolerancia gástrica a la metformina tomada con desayuno.',
                recomendaciones='Evitar azúcares simples y harinas refinadas en horas de la noche.',
                fecha_ultima_revision=date(2026, 7, 5),
                proxima_cita=date(2026, 10, 15),
                instrucciones='Ingerir con los alimentos de la mañana.',
                color='#0284C7'
            )
            db.session.add(t2)
            db.session.flush()

        # Medicamentos de Prueba vinculados a Tratamientos
        m1 = Medicamento.query.filter_by(usuario_id=u1.id, nombre='Losartán Potásico').first()
        if not m1:
            m1 = Medicamento(
                usuario_id=u1.id,
                tratamiento_id=t1.id,
                nombre='Losartán Potásico',
                miligramos='50 mg',
                frecuencia=12,
                cantidad_restante=28,
                esta_tomado=False,
                icono='💊',
                notas='1 pastilla cada 12 horas para control de presión arterial',
                hora_alarma=time(8, 0)
            )
            db.session.add(m1)
        else:
            m1.tratamiento_id = t1.id

        m2 = Medicamento.query.filter_by(usuario_id=u1.id, nombre='Metformina').first()
        if not m2:
            m2 = Medicamento(
                usuario_id=u1.id,
                tratamiento_id=t2.id,
                nombre='Metformina',
                miligramos='850 mg',
                frecuencia=24,
                cantidad_restante=15,
                esta_tomado=True,
                icono='💊',
                notas='1 pastilla con el desayuno',
                hora_alarma=time(7, 30)
            )
            db.session.add(m2)
        else:
            m2.tratamiento_id = t2.id

        m3 = Medicamento.query.filter_by(usuario_id=u1.id, nombre='Acetaminofén').first()
        if not m3:
            m3 = Medicamento(
                usuario_id=u1.id,
                tratamiento_id=None,
                nombre='Acetaminofén',
                miligramos='500 mg',
                frecuencia=8,
                cantidad_restante=4,
                esta_tomado=False,
                icono='💊',
                notas='Para dolores articulares leves si es necesario (SOS)',
                hora_alarma=time(14, 0)
            )
            db.session.add(m3)

        # 4. Metas de Salud para Usuario 1 si no existen
        if Meta.query.filter_by(usuario_id=u1.id).count() == 0:
            meta1 = Meta(
                usuario_id=u1.id,
                nombre='Tomar agua durante el día',
                objetivo=8,
                progreso=5,
                unidad='vasos',
                icono='💧',
                completada=False
            )
            meta2 = Meta(
                usuario_id=u1.id,
                nombre='Caminata matutina en el parque',
                objetivo=20,
                progreso=20,
                unidad='minutos',
                icono='🚶',
                completada=True
            )
            db.session.add_all([meta1, meta2])

        # 5. Contactos para Usuario 1 si no existen
        if Contacto.query.filter_by(usuario_id=u1.id).count() == 0:
            c1 = Contacto(
                usuario_id=u1.id,
                nombre='Carolina Gómez (Hija)',
                telefono='3001234567',
                categoria='Familia',
                es_favorito=True,
                es_emergencia=True,
                icono='👩'
            )
            c2 = Contacto(
                usuario_id=u1.id,
                nombre='Dr. Fernando Ramírez',
                telefono='6013456789',
                categoria='Médico',
                es_favorito=True,
                es_emergencia=False,
                icono='👨‍⚕️'
            )
            db.session.add_all([c1, c2])

        # 6. Actividades Cognitivas / Minijuegos para poblar el Salón de la Fama
        from app.models.actividad_cognitiva import ActividadCognitiva
        for user in [u1, u2]:
            if ActividadCognitiva.query.filter_by(usuario_id=user.id).count() == 0:
                actividades = [
                    ActividadCognitiva(
                        usuario_id=user.id,
                        tipo_juego='Sudoku',
                        puntaje=350,
                    ),
                    ActividadCognitiva(
                        usuario_id=user.id,
                        tipo_juego='Buscar Pares',
                        puntaje=280,
                    ),
                    ActividadCognitiva(
                        usuario_id=user.id,
                        tipo_juego='Sopa de Letras',
                        puntaje=220,
                    ),
                    ActividadCognitiva(
                        usuario_id=user.id,
                        tipo_juego='Trivia de Cultura General',
                        puntaje=180,
                    ),
                    ActividadCognitiva(
                        usuario_id=user.id,
                        tipo_juego='Secuencia de Luces',
                        puntaje=150,
                    ),
                ]
                db.session.add_all(actividades)

        # 7. Medicamentos y Metas para Usuario 2 si no existen
        if Medicamento.query.filter_by(usuario_id=u2.id).count() == 0:
            m_demo = Medicamento(
                usuario_id=u2.id,
                nombre='Metformina',
                miligramos='850 mg',
                frecuencia=12,
                cantidad_restante=30,
                esta_tomado=False,
                icono='💊',
                notas='1 tableta con las comidas principales',
                hora_alarma=time(8, 30)
            )
            db.session.add(m_demo)

        if Meta.query.filter_by(usuario_id=u2.id).count() == 0:
            meta_demo = Meta(
                usuario_id=u2.id,
                nombre='Beber agua fresca',
                objetivo=6,
                progreso=4,
                unidad='vasos',
                icono='💧',
                completada=False
            )
            db.session.add(meta_demo)

        if Contacto.query.filter_by(usuario_id=u2.id).count() == 0:
            c_demo = Contacto(
                usuario_id=u2.id,
                nombre='Andrés Pérez (Esposo)',
                telefono='3119876543',
                categoria='Familia',
                es_favorito=True,
                es_emergencia=True,
                icono='👨'
            )
            db.session.add(c_demo)

        db.session.commit()
        print("[EXITO] Base de datos sembrada con exito.")
        print("Credenciales de acceso disponibles:")
        print("  1. Adulto Mayor: santiago@envejecer.com  | Contrasena: password123 (Codigo: ECB-1001)")
        print("  2. Adulto Demo:  prueba@envejecer.com    | Contrasena: password123 (Codigo: ECB-1002)")
        print("  3. Cuidador:     cuidador@envejecer.com  | Contrasena: password123 (Vinculado a Santiago)")

if __name__ == '__main__':
    run_seed()
