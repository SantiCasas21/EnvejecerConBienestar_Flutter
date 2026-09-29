"""Modelo de Usuario."""
from app.extensions import db
from datetime import datetime, timezone
from werkzeug.security import generate_password_hash, check_password_hash

class Usuario(db.Model):
    """Entidad de Usuario en la base de datos."""
    __tablename__ = 'usuarios'
    
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relaciones
    perfil = db.relationship('PerfilUsuario', backref='usuario', uselist=False, cascade='all, delete-orphan')
    medicamentos = db.relationship('Medicamento', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')
    contactos = db.relationship('Contacto', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')
    habitos = db.relationship('Habito', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')
    metas = db.relationship('Meta', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')
    actividades_cognitivas = db.relationship('ActividadCognitiva', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')

    def set_password(self, password: str) -> None:
        """Hashea y guarda la contraseña."""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        """Verifica si la contraseña dada coincide con el hash."""
        return check_password_hash(self.password_hash, password)

    def to_dict(self) -> dict:
        """Retorna representación en diccionario."""
        return {
            "id": self.id,
            "nombre": self.nombre,
            "email": self.email,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
