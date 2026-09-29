"""Modelo de Actividad Cognitiva (Juegos)."""
from app.extensions import db
from datetime import datetime, timezone

class ActividadCognitiva(db.Model):
    """Entidad de Actividad Cognitiva en la base de datos."""
    __tablename__ = 'actividades_cognitivas'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    tipo_juego = db.Column(db.String(50), nullable=False)
    puntaje = db.Column(db.Integer, nullable=False)
    fecha_realizacion = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
