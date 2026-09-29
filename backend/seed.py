"""Script de siembra (seed) para poblar usuarios y datos de prueba completos."""
from datetime import datetime, time
from app import create_app
from app.extensions import db
from app.models.usuario import Usuario
from app.models.perfil import PerfilUsuario
from app.models.medicamento import Medicamento
from app.models.meta import Meta
from app.models.contacto import Contacto

def run_seed():
    app = create_app()
    with app.app_context():
        print("[SEED] Sembrando base de datos con usuarios y datos de prueba...")

        # 1. Usuario Principal: Santiago
        u1 = Usuario.query.filter_by(email='santiago@envejecer.com').first()
        if not u1:
            u1 = Usuario(nombre='Santiago Gómez', email='santiago@envejecer.com')
            db.session.add(u1)
            db.session.flush()
        u1.nombre = 'Santiago Gómez'
        u1.set_password('password123')

        # Perfil Médico de Santiago
        p1 = PerfilUsuario.query.filter_by(usuario_id=u1.id).first()
        if not p1:
            p1 = PerfilUsuario(usuario_id=u1.id)
            db.session.add(p1)
        p1.fecha_nacimiento = '1951-05-14'
        p1.edad = 75
        p1.genero = 'Masculino'
        p1.tipo_sangre = 'O+'
        p1.peso = 68.5
        p1.altura = 165.0
        p1.eps = 'SURA EPS'
        p1.telefono = '3109876543'
        p1.alergias = 'Penicilina, Mariscos'
        p1.condiciones = 'Hipertensión arterial controlada, Artrosis leve'
        p1.cirugias = 'Apendicectomía (1985)'
        p1.dispositivos_medicos = 'Lentes para lectura, Bastón para caminatas'
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
            u2 = Usuario(nombre='Adulto Mayor Demo', email='prueba@envejecer.com')
            db.session.add(u2)
            db.session.flush()
        u2.nombre = 'Adulto Mayor Demo'
        u2.set_password('password123')

        # Perfil de Demo
        p2 = PerfilUsuario.query.filter_by(usuario_id=u2.id).first()
        if not p2:
            p2 = PerfilUsuario(usuario_id=u2.id)
            db.session.add(p2)
        p2.fecha_nacimiento = '1948-11-20'
        p2.edad = 77
        p2.genero = 'Femenino'
        p2.tipo_sangre = 'A+'
        p2.peso = 62.0
        p2.altura = 158.0
        p2.eps = 'Sanitas EPS'
        p2.telefono = '3201234567'
        p2.alergias = 'Ninguna'
        p2.condiciones = 'Diabetes Tipo 2'
        p2.contacto_emergencia_nombre = 'Andrés Pérez'
        p2.contacto_emergencia_telefono = '3119876543'
        p2.contacto_emergencia_parentesco = 'Cónyuge / Pareja'
        p2.medico_tratante = 'Dra. Marcela Torres'
        p2.telefono_medico = '6017654321'

        # 3. Medicamentos de Prueba para Usuario 1 si no existen
        if Medicamento.query.filter_by(usuario_id=u1.id).count() == 0:
            m1 = Medicamento(
                usuario_id=u1.id,
                nombre='Losartán Potásico',
                miligramos='50 mg',
                frecuencia=12,
                cantidad_restante=28,
                esta_tomado=False,
                icono='💊',
                notas='1 pastilla cada 12 horas para control de presión arterial',
                hora_alarma=time(8, 0)
            )
            m2 = Medicamento(
                usuario_id=u1.id,
                nombre='Metformina',
                miligramos='850 mg',
                frecuencia=24,
                cantidad_restante=15,
                esta_tomado=True,
                icono='💊',
                notas='1 pastilla con el desayuno',
                hora_alarma=time(7, 30)
            )
            m3 = Medicamento(
                usuario_id=u1.id,
                nombre='Acetaminofén',
                miligramos='500 mg',
                frecuencia=8,
                cantidad_restante=4,
                esta_tomado=False,
                icono='💊',
                notas='Para dolores articulares leves si es necesario',
                hora_alarma=time(14, 0)
            )
            db.session.add_all([m1, m2, m3])

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

        db.session.commit()
        print("[EXITO] Base de datos sembrada con exito.")
        print("Credenciales de acceso disponibles:")
        print("  1. Email: santiago@envejecer.com  | Contrasena: password123")
        print("  2. Email: prueba@envejecer.com     | Contrasena: password123")

if __name__ == '__main__':
    run_seed()
