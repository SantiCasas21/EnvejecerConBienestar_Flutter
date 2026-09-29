"""Esquemas para Medicamento."""
from app.extensions import ma
from app.models.medicamento import Medicamento
from marshmallow import fields, validate, EXCLUDE

class MedicamentoSchema(ma.SQLAlchemyAutoSchema):
    """Esquema completo de Medicamento."""
    class Meta:
        model = Medicamento
        include_fk = True
        load_instance = True
        unknown = EXCLUDE

    alerta_inventario = fields.Boolean(dump_only=True)
    tomas_por_dia = fields.Integer(dump_only=True)
    dias_autonomia = fields.Integer(dump_only=True)

class MedicamentoCreateSchema(ma.Schema):
    """Esquema para validar creación y edición de Medicamento."""
    class Meta:
        unknown = EXCLUDE

    nombre = fields.String(required=True, validate=validate.Length(min=1, max=100))
    miligramos = fields.String(validate=validate.Length(max=50), missing=None, allow_none=True)
    notas = fields.String(missing=None, allow_none=True)
    frecuencia = fields.Integer(missing=8, allow_none=True)
    hora_alarma = fields.Time(missing=None, allow_none=True)
    esta_tomado = fields.Boolean(missing=False, allow_none=True)
    icono = fields.String(validate=validate.Length(max=20), missing='💊', allow_none=True)
    fecha_inicio = fields.Date(missing=None, allow_none=True)
    cantidad_restante = fields.Integer(missing=30, allow_none=True)
    umbral_alerta = fields.Integer(missing=5, allow_none=True)
    tratamiento_id = fields.Integer(missing=None, allow_none=True)
    color_icono = fields.String(missing=None, allow_none=True)
