"""Modelo de Habito."""
from app.extensions import db
from datetime import datetime, timezone

class Habito(db.Model):
    """Entidad de Habito en la base de datos."""
    __tablename__ = 'habitos'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    tipo = db.Column(db.String(50), nullable=False)
    meta = db.Column(db.Integer, nullable=False)
    progreso_actual = db.Column(db.Integer, default=0)
    fecha = db.Column(db.Date, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    @property
    def porcentaje(self) -> float:
        """Calcula el porcentaje de progreso del hábito."""
        if self.meta == 0:
            return 0.0
        return min((self.progreso_actual / self.meta) * 100, 100.0)
