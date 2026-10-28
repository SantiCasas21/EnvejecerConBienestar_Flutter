"""Esquemas Marshmallow para HistorialToma."""
from app.extensions import ma
from app.models.historial_toma import HistorialToma
from marshmallow import fields, validate, EXCLUDE

class HistorialTomaSchema(ma.SQLAlchemyAutoSchema):
    """Esquema de serialización completa de HistorialToma."""
    class Meta:
        model = HistorialToma
        include_fk = True
        load_instance = True
        unknown = EXCLUDE

    medicamento_nombre = fields.String(dump_only=True)
    medicamento_icono = fields.String(dump_only=True)
    medicamento_miligramos = fields.String(dump_only=True)
    medicamento_color = fields.String(dump_only=True)

class HistorialTomaCreateSchema(ma.Schema):
    """Esquema de validación para registrar un evento de toma."""
    class Meta:
        unknown = EXCLUDE

    medicamento_id = fields.Integer(required=True)
    fecha = fields.Date(missing=None, allow_none=True)
    hora_programada = fields.String(missing=None, allow_none=True)
    estado = fields.String(
        missing='tomada',
        validate=validate.OneOf(['tomada', 'pospuesta', 'omitida'])
    )
    notas = fields.String(missing=None, allow_none=True)
    paciente_id = fields.Integer(missing=None, allow_none=True)
