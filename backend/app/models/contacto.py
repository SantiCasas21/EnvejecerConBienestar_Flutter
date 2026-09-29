"""Modelo de Contacto."""
from app.extensions import db
from datetime import datetime, timezone

class Contacto(db.Model):
    """Entidad de Contacto en la base de datos."""
    __tablename__ = 'contactos'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    nombre = db.Column(db.String(100), nullable=False)
    telefono = db.Column(db.String(20), nullable=False)
    ubicacion = db.Column(db.String(200))
    categoria = db.Column(db.String(50), default='Familia/Amigos')
    icono = db.Column(db.String(20), default='👤')
    es_favorito = db.Column(db.Boolean, default=False)
    es_emergencia = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
