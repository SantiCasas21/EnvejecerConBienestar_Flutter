"""Servicio de Contactos."""
from app.models.contacto import Contacto
from app.extensions import db
from typing import List, Optional, Dict, Any

class ContactoService:
    """Servicios para la entidad Contacto."""

    @staticmethod
    def get_all(usuario_id: int) -> List[Contacto]:
        """Obtiene todos los contactos de un usuario."""
        return Contacto.query.filter_by(usuario_id=usuario_id).all()

    @staticmethod
    def get_by_id(id: int, usuario_id: int) -> Optional[Contacto]:
        """Obtiene un contacto específico."""
        return Contacto.query.filter_by(id=id, usuario_id=usuario_id).first()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Contacto:
        """Crea un nuevo contacto."""
        contacto = Contacto(usuario_id=usuario_id, **data)
        db.session.add(contacto)
        db.session.commit()
        return contacto

    @staticmethod
    def update(id: int, data: Dict[str, Any], usuario_id: int) -> Optional[Contacto]:
        """Actualiza un contacto."""
        contacto = ContactoService.get_by_id(id, usuario_id)
        if not contacto:
            return None
            
        for key, value in data.items():
            if hasattr(contacto, key):
                setattr(contacto, key, value)
                
        db.session.commit()
        return contacto

    @staticmethod
    def delete(id: int, usuario_id: int) -> bool:
        """Elimina un contacto."""
        contacto = ContactoService.get_by_id(id, usuario_id)
        if not contacto:
            return False
            
        db.session.delete(contacto)
        db.session.commit()
        return True

    @staticmethod
    def get_emergencia(usuario_id: int) -> List[Contacto]:
        """Obtiene los contactos de emergencia de un usuario."""
        return Contacto.query.filter_by(usuario_id=usuario_id, es_emergencia=True).all()

    @staticmethod
    def sincronizar_lote(items: List[Dict[str, Any]], usuario_id: int) -> Dict[str, Any]:
        """Sincroniza una lista de contactos desde la agenda del teléfono evitando duplicados por teléfono."""
        existentes = ContactoService.get_all(usuario_id)
        telefonos_existentes = {
            ''.join(ch for ch in (c.telefono or '') if ch.isdigit())[-10:]
            for c in existentes
            if c.telefono
        }

        creados: List[Contacto] = []
        omitidos = 0
        for item in items:
            nombre = (item.get('nombre') or '').strip()
            telefono = (item.get('telefono') or '').strip()
            digitos = ''.join(ch for ch in telefono if ch.isdigit())[-10:]
            if not nombre or not digitos or digitos in telefonos_existentes:
                omitidos += 1
                continue

            contacto = Contacto(
                usuario_id=usuario_id,
                nombre=nombre[:100],
                telefono=telefono[:20],
                ubicacion=(item.get('ubicacion') or '')[:200],
                categoria=(item.get('categoria') or 'Familia/Amigos')[:50],
                icono=(item.get('icono') or '👤')[:20],
                es_favorito=bool(item.get('es_favorito', False)),
                es_emergencia=bool(item.get('es_emergencia', False)),
            )
            db.session.add(contacto)
            creados.append(contacto)
            telefonos_existentes.add(digitos)

        if creados:
            db.session.commit()

        return {'creados': creados, 'omitidos': omitidos}
