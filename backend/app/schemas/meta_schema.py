"""Esquema de serialización para Meta."""
from app.extensions import ma
from app.models.meta import Meta
from marshmallow import fields, validate

class MetaSchema(ma.SQLAlchemyAutoSchema):
    """Esquema completo de Meta."""
    class Meta:
        model = Meta
        include_fk = True
        load_instance = True

    porcentaje = fields.Float(dump_only=True)

class MetaCreateSchema(ma.Schema):
    """Esquema para crear/validar Meta."""
    nombre = fields.String(required=True, validate=validate.Length(min=1, max=100))
    objetivo = fields.Integer(missing=1)
    progreso = fields.Integer(missing=0)
    unidad = fields.String(missing='vasos')
    icono = fields.String(missing='🎯')
    fecha_inicio = fields.Date(missing=None)
    fecha_fin = fields.Date(missing=None)
    completada = fields.Boolean(missing=False)
