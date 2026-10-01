"""Modelo de Actividad Cognitiva (Juegos)."""
from app.extensions import db
from datetime import datetime, timezone

class ActividadCognitiva(db.Model):
    """Entidad de Actividad Cognitiva en la base de datos."""
    __tablename__ = 'actividades_cognitivas'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False, index=True)
    tipo_juego = db.Column(db.String(50), nullable=False, index=True)
    puntaje = db.Column(db.Integer, nullable=False)
    nivel_dificultad = db.Column(db.String(20), default='intermedio', nullable=False)
    fecha_realizacion = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), index=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        """Representación en diccionario de la actividad cognitiva."""
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "tipo_juego": self.tipo_juego,
            "puntaje": self.puntaje,
            "nivel_dificultad": self.nivel_dificultad,
            "fecha_realizacion": self.fecha_realizacion.isoformat() if self.fecha_realizacion else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
