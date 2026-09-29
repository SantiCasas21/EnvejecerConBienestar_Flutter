"""Esquemas para Tratamiento."""
from app.extensions import ma
from app.models.tratamiento import Tratamiento
from app.schemas.medicamento_schema import MedicamentoSchema
from marshmallow import fields, validate, EXCLUDE

class TratamientoSchema(ma.SQLAlchemyAutoSchema):
    """Esquema completo de Tratamiento con datos calculados y medicamentos anidados."""
    class Meta:
        model = Tratamiento
        include_fk = True
        load_instance = True
        unknown = EXCLUDE

    medicamentos = fields.Nested(MedicamentoSchema, many=True, dump_only=True)
    dias_transcurridos = fields.Integer(dump_only=True)
    dias_totales = fields.Integer(dump_only=True)
    progreso_dias = fields.Float(dump_only=True)
    total_medicamentos = fields.Method('get_total_medicamentos', dump_only=True)

    def get_total_medicamentos(self, obj) -> int:
        return len(obj.medicamentos) if obj.medicamentos else 0

class TratamientoCreateSchema(ma.Schema):
    """Esquema para validar creación y edición de Tratamiento."""
    class Meta:
        unknown = EXCLUDE

    diagnostico = fields.String(required=True, validate=validate.Length(min=2, max=120))
    medico_tratante = fields.String(validate=validate.Length(max=120), missing=None, allow_none=True)
    institucion_salud = fields.String(validate=validate.Length(max=120), missing=None, allow_none=True)
    fecha_inicio = fields.Date(missing=None, allow_none=True)
    fecha_fin = fields.Date(missing=None, allow_none=True)
    es_cronico = fields.Boolean(missing=False, allow_none=True)
    estado = fields.String(validate=validate.OneOf(['activo', 'completado', 'suspendido']), missing='activo')
    instrucciones = fields.String(missing=None, allow_none=True)
    color = fields.String(missing='#0D9488', allow_none=True)
    medicamento_ids = fields.List(fields.Integer(), missing=None, allow_none=True)
