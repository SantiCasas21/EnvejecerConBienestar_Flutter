"""Esquemas para Actividad Cognitiva."""
from app.extensions import ma
from app.models.actividad_cognitiva import ActividadCognitiva

class ActividadCognitivaSchema(ma.SQLAlchemyAutoSchema):
    """Esquema completo de Actividad Cognitiva."""
    class Meta:
        model = ActividadCognitiva
        include_fk = True
        load_instance = True
