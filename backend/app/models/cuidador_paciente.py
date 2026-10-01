"""Modelo de relación entre Cuidador y Paciente (Adulto Mayor)."""
from app.extensions import db
from datetime import datetime, timezone

class CuidadorPaciente(db.Model):
    """Entidad relacional que vincula a un Cuidador con un Adulto Mayor supervisado."""
    __tablename__ = 'cuidador_pacientes'

    id = db.Column(db.Integer, primary_key=True)
    cuidador_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False, index=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False, index=True)
    parentesco = db.Column(db.String(60), default='Familiar / Cuidador', nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Restricción de unicidad para evitar vinculaciones duplicadas
    __table_args__ = (
        db.UniqueConstraint('cuidador_id', 'paciente_id', name='uq_cuidador_paciente'),
    )

    # Relaciones hacia Usuario
    cuidador = db.relationship('Usuario', foreign_keys=[cuidador_id], backref=db.backref('vinculos_pacientes', lazy='dynamic', cascade='all, delete-orphan'))
    paciente = db.relationship('Usuario', foreign_keys=[paciente_id], backref=db.backref('vinculos_cuidadores', lazy='dynamic', cascade='all, delete-orphan'))

    def to_dict(self) -> dict:
        """Representación en diccionario."""
        return {
            "id": self.id,
            "cuidador_id": self.cuidador_id,
            "paciente_id": self.paciente_id,
            "parentesco": self.parentesco,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
