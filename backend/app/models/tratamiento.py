"""Modelo de Tratamiento Médico."""
from app.extensions import db
from datetime import datetime, date, timezone

class Tratamiento(db.Model):
    """Entidad de Tratamiento Clínico que agrupa medicamentos y prescripciones."""
    __tablename__ = 'tratamientos'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    diagnostico = db.Column(db.String(120), nullable=False)
    medico_tratante = db.Column(db.String(120))
    institucion_salud = db.Column(db.String(120))
    fecha_inicio = db.Column(db.Date, default=date.today, nullable=False)
    fecha_fin = db.Column(db.Date, nullable=True)
    es_cronico = db.Column(db.Boolean, default=False)
    estado = db.Column(db.String(20), default='activo')  # activo, completado, suspendido
    instrucciones = db.Column(db.Text)
    color = db.Column(db.String(20), default='#0D9488')
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relación uno-a-muchos con Medicamento
    medicamentos = db.relationship('Medicamento', backref='tratamiento', lazy=True)

    @property
    def dias_transcurridos(self) -> int:
        """Calcula los días transcurridos desde el inicio del tratamiento."""
        if not self.fecha_inicio:
            return 0
        hoy = date.today()
        diff = (hoy - self.fecha_inicio).days
        return max(0, diff)

    @property
    def dias_totales(self) -> int:
        """Calcula la duración total planificada en días si no es crónico."""
        if self.es_cronico or not self.fecha_fin or not self.fecha_inicio:
            return 0
        diff = (self.fecha_fin - self.fecha_inicio).days
        return max(1, diff)

    @property
    def progreso_dias(self) -> float:
        """Porcentaje de avance del tratamiento temporal (0.0 a 100.0). Para crónicos retorna 100.0."""
        if self.es_cronico:
            return 100.0
        totales = self.dias_totales
        if totales <= 0:
            return 100.0
        avance = (self.dias_transcurridos / totales) * 100.0
        return min(100.0, max(0.0, round(avance, 1)))
