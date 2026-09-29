"""Esquemas para Contacto."""
from app.extensions import ma
from app.models.contacto import Contacto

class ContactoSchema(ma.SQLAlchemyAutoSchema):
    """Esquema completo de Contacto."""
    class Meta:
        model = Contacto
        include_fk = True
        load_instance = True
