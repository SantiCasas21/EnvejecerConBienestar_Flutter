"""Modelo de Medicamento."""
from app.extensions import db
from datetime import datetime, timezone

class Medicamento(db.Model):
    """Entidad de Medicamento en la base de datos."""
    __tablename__ = 'medicamentos'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    tratamiento_id = db.Column(db.Integer, db.ForeignKey('tratamientos.id'), nullable=True)
    nombre = db.Column(db.String(100), nullable=False)
    miligramos = db.Column(db.String(50))
    notas = db.Column(db.Text)
    frecuencia = db.Column(db.Integer)  # en horas
    hora_alarma = db.Column(db.Time)
    esta_tomado = db.Column(db.Boolean, default=False)
    cantidad_restante = db.Column(db.Integer, default=30)
    umbral_alerta = db.Column(db.Integer, default=5)
    icono = db.Column(db.String(20), default='💊')
    fecha_inicio = db.Column(db.Date)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    @property
    def alerta_inventario(self) -> bool:
        """Determina si las pastillas restantes alcanzaron o bajaron del umbral de alerta."""
        if self.cantidad_restante is None or self.umbral_alerta is None:
            return False
        return self.cantidad_restante <= self.umbral_alerta

    @property
    def tomas_por_dia(self) -> int:
        """Calcula cuántas tomas corresponden al día según la frecuencia."""
        if not self.frecuencia or self.frecuencia <= 0:
            return 1
        return max(1, 24 // self.frecuencia)

    @property
    def dias_autonomia(self) -> int:
        """Calcula los días estimados de medicación restantes en base a cantidad y tomas por día."""
        if self.cantidad_restante is None or self.cantidad_restante <= 0:
            return 0
        return self.cantidad_restante // self.tomas_por_dia
