"""Esquemas para Habito."""
from app.extensions import ma
from app.models.habito import Habito
from marshmallow import fields

class HabitoSchema(ma.SQLAlchemyAutoSchema):
    """Esquema completo de Habito."""
    class Meta:
        model = Habito
        include_fk = True
        load_instance = True
    
    porcentaje = fields.Float(dump_only=True)
