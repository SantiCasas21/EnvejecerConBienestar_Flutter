"""Modelo de Meta."""
from app.extensions import db
from datetime import datetime, timezone

class Meta(db.Model):
    """Entidad de Meta de bienestar en la base de datos."""
    __tablename__ = 'metas'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    nombre = db.Column(db.String(100), nullable=False)
    objetivo = db.Column(db.Integer, nullable=False, default=1)
    progreso = db.Column(db.Integer, nullable=False, default=0)
    unidad = db.Column(db.String(50), default='vasos')
    icono = db.Column(db.String(20), default='🎯')
    fecha_inicio = db.Column(db.Date, nullable=False, default=lambda: datetime.now(timezone.utc).date())
    fecha_fin = db.Column(db.Date, nullable=True)
    completada = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    @property
    def porcentaje(self) -> float:
        """Calcula el porcentaje de avance de la meta."""
        if self.objetivo == 0:
            return 0.0
        return min((self.progreso / self.objetivo) * 100, 100.0)
