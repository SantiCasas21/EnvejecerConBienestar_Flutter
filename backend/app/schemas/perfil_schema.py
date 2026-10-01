"""Esquema de PerfilUsuario."""
from app.extensions import ma
from app.models.perfil import PerfilUsuario
from marshmallow import fields, EXCLUDE

class PerfilUsuarioSchema(ma.SQLAlchemyAutoSchema):
    """Esquema completo de PerfilUsuario con soporte de Habeas Data."""
    class Meta:
        model = PerfilUsuario
        include_fk = True
        load_instance = True
        unknown = EXCLUDE

    acepto_habeas_data = fields.Boolean(missing=False)
    fecha_habeas_data = fields.DateTime(dump_only=True)
    imc = fields.Float(dump_only=True)
    clasificacion_imc = fields.String(dump_only=True)
