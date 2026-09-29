"""Modelo de Perfil de Usuario con Ficha Médica Integral y Habeas Data."""
from app.extensions import db
from datetime import datetime, timezone

class PerfilUsuario(db.Model):
    """Entidad de PerfilUsuario en la base de datos."""
    __tablename__ = 'perfil_usuario'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False, unique=True)
    
    # ── Datos Personales y Biométricos ──
    fecha_nacimiento = db.Column(db.String(20), nullable=True) # YYYY-MM-DD o DD/MM/YYYY
    edad = db.Column(db.Integer, nullable=True)
    genero = db.Column(db.String(20), default='No especificado')
    tipo_sangre = db.Column(db.String(10), default='O+')
    peso = db.Column(db.Float, nullable=True) # en kg
    altura = db.Column(db.Float, nullable=True) # en cm
    
    # ── Cobertura y Cuidados Clínicos ──
    eps = db.Column(db.String(100), default='No especificada')
    alergias = db.Column(db.Text, default='Ninguna')
    condiciones = db.Column(db.Text, default='Ninguna')
    cirugias = db.Column(db.Text, default='Ninguna')
    dispositivos_medicos = db.Column(db.String(255), default='Ninguno')
    
    # ── Contactos de Emergencia y Red Médica ──
    telefono = db.Column(db.String(25), nullable=True) # Teléfono propio
    contacto_emergencia_nombre = db.Column(db.String(120), nullable=True)
    contacto_emergencia_telefono = db.Column(db.String(25), nullable=True)
    contacto_emergencia_parentesco = db.Column(db.String(50), default='Familiar')
    medico_tratante = db.Column(db.String(120), nullable=True)
    telefono_medico = db.Column(db.String(25), nullable=True)
    clinica_preferida = db.Column(db.String(150), default='Hospital General')
    
    # ── Cumplimiento Legal: Ley 1581 de 2012 (Habeas Data) ──
    acepto_habeas_data = db.Column(db.Boolean, default=False, nullable=False)
    fecha_habeas_data = db.Column(db.DateTime, nullable=True)

    # ── Notas y Observaciones ──
    notas_adicionales = db.Column(db.Text, nullable=True)
    
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
