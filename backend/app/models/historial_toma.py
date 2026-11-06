"""Modelo de Historial de Tomas de Medicamentos."""
from app.extensions import db
from datetime import datetime, date, timezone

class HistorialToma(db.Model):
    """Entidad que registra cada evento de toma, postergación u omisión de un medicamento."""
    __tablename__ = 'historial_tomas'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False, index=True)
    medicamento_id = db.Column(db.Integer, db.ForeignKey('medicamentos.id'), nullable=False, index=True)
    fecha = db.Column(db.Date, nullable=False, default=date.today, index=True)
    hora_programada = db.Column(db.String(10), nullable=False)  # Ej: '08:00'
    hora_real = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    estado = db.Column(db.String(20), nullable=False, default='tomada')  # 'tomada', 'pospuesta', 'omitida'
    notas = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relaciones
    usuario = db.relationship('Usuario', backref=db.backref('historial_tomas', lazy='dynamic', cascade='all, delete-orphan'))
    medicamento = db.relationship('Medicamento', backref=db.backref('historial_tomas', lazy='dynamic', cascade='all, delete-orphan'))

    @property
    def medicamento_nombre(self) -> str | None:
        """Nombre del medicamento asociado."""
        return self.medicamento.nombre if self.medicamento else None

    @property
    def medicamento_icono(self) -> str:
        """Icono del medicamento asociado."""
        return self.medicamento.icono if self.medicamento else '💊'

    @property
    def medicamento_miligramos(self) -> str | None:
        """Miligramos o dosificación del medicamento asociado."""
        return self.medicamento.miligramos if self.medicamento else None

    @property
    def medicamento_color(self) -> str:
        """Color temático del medicamento asociado."""
        return getattr(self.medicamento, 'color_icono', '#0D9488') or '#0D9488'

    def to_dict(self) -> dict:
        """Serializa la entidad a diccionario con datos útiles del medicamento."""
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "medicamento_id": self.medicamento_id,
            "medicamento_nombre": self.medicamento_nombre,
            "medicamento_icono": self.medicamento_icono,
            "medicamento_miligramos": self.medicamento_miligramos,
            "medicamento_color": self.medicamento_color,
            "fecha": self.fecha.isoformat() if self.fecha else None,
            "hora_programada": self.hora_programada,
            "hora_real": self.hora_real.isoformat() if self.hora_real else None,
            "estado": self.estado,
            "notas": self.notas,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
