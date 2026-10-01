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
    especialidad_medica = db.Column(db.String(100), default='Medicina General')
    objetivo_terapeutico = db.Column(db.String(200), nullable=True)
    notas_evolucion = db.Column(db.Text, nullable=True)
    recomendaciones = db.Column(db.Text, nullable=True)
    fecha_ultima_revision = db.Column(db.Date, nullable=True)
    proxima_cita = db.Column(db.Date, nullable=True)
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

    @property
    def adherencia_porcentaje(self) -> float:
        """Calcula el porcentaje de adherencia en el día en base a los medicamentos vinculados."""
        if not self.medicamentos:
            return 100.0
        total = len(self.medicamentos)
        tomados = sum(1 for m in self.medicamentos if m.esta_tomado)
        return round((tomados / total) * 100.0, 1)

    def to_dict(self) -> dict:
        """Representación en diccionario enriquecida para API y expediente."""
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "diagnostico": self.diagnostico,
            "especialidad_medica": self.especialidad_medica or 'Medicina General',
            "medico_tratante": self.medico_tratante,
            "institucion_salud": self.institucion_salud,
            "fecha_inicio": self.fecha_inicio.isoformat() if self.fecha_inicio else None,
            "fecha_fin": self.fecha_fin.isoformat() if self.fecha_fin else None,
            "es_cronico": bool(self.es_cronico),
            "estado": self.estado or 'activo',
            "objetivo_terapeutico": self.objetivo_terapeutico,
            "notas_evolucion": self.notas_evolucion,
            "recomendaciones": self.recomendaciones,
            "fecha_ultima_revision": self.fecha_ultima_revision.isoformat() if self.fecha_ultima_revision else None,
            "proxima_cita": self.proxima_cita.isoformat() if self.proxima_cita else None,
            "instrucciones": self.instrucciones,
            "color": self.color or '#0D9488',
            "dias_transcurridos": self.dias_transcurridos,
            "dias_totales": self.dias_totales,
            "progreso_dias": self.progreso_dias,
            "adherencia_porcentaje": self.adherencia_porcentaje,
            "total_medicamentos": len(self.medicamentos) if self.medicamentos else 0,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
