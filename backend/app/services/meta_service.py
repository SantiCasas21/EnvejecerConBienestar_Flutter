"""Servicio para administrar Metas de bienestar."""
from app.models.meta import Meta
from app.extensions import db
from typing import List, Optional, Dict, Any

class MetaService:
    """Lógica de negocio para las metas."""

    @staticmethod
    def get_all(usuario_id: int) -> List[Meta]:
        """Obtiene todas las metas del usuario."""
        return Meta.query.filter_by(usuario_id=usuario_id).order_by(Meta.created_at.desc()).all()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Meta:
        """Crea una nueva meta."""
        meta = Meta(usuario_id=usuario_id, **data)
        db.session.add(meta)
        db.session.commit()
        return meta

    @staticmethod
    def incrementar_progreso(id: int, valor: int, usuario_id: int) -> Optional[Meta]:
        """Incrementa el progreso de una meta y marca completada si alcanza el objetivo."""
        meta = Meta.query.filter_by(id=id, usuario_id=usuario_id).first()
        if not meta:
            return None
        
        meta.progreso += valor
        if meta.progreso >= meta.objetivo:
            meta.completada = True
            
        db.session.commit()
        return meta

    @staticmethod
    def delete(id: int, usuario_id: int) -> bool:
        """Elimina una meta."""
        meta = Meta.query.filter_by(id=id, usuario_id=usuario_id).first()
        if not meta:
            return False
        db.session.delete(meta)
        db.session.commit()
        return True
