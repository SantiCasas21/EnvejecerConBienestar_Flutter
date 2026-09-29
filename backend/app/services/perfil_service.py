"""Servicio de Perfil de Usuario."""
from app.models.perfil import PerfilUsuario
from app.extensions import db
from datetime import datetime, timezone
from typing import Optional, Dict, Any

class PerfilService:
    """Lógica de negocio para PerfilUsuario."""

    @staticmethod
    def get_by_usuario_id(usuario_id: int) -> Optional[PerfilUsuario]:
        """Obtiene el perfil del usuario."""
        return PerfilUsuario.query.filter_by(usuario_id=usuario_id).first()

    @staticmethod
    def guardar_o_actualizar(data: Dict[str, Any], usuario_id: int) -> PerfilUsuario:
        """Crea o actualiza el perfil del usuario asegurando registro de consentimiento Habeas Data."""
        perfil = PerfilUsuario.query.filter_by(usuario_id=usuario_id).first()
        
        # Filtrar campos que no pertenezcan al modelo o sean id/usuario_id
        ignored_keys = {'id', 'usuario_id', 'created_at', 'updated_at'}
        valid_data = {k: v for k, v in data.items() if hasattr(PerfilUsuario, k) and k not in ignored_keys}

        # Manejo legal de Habeas Data
        if valid_data.get('acepto_habeas_data') is True:
            if not perfil or not perfil.fecha_habeas_data:
                valid_data['fecha_habeas_data'] = datetime.now(timezone.utc)

        if not perfil:
            perfil = PerfilUsuario(usuario_id=usuario_id, **valid_data)
            db.session.add(perfil)
        else:
            for key, value in valid_data.items():
                setattr(perfil, key, value)
        
        db.session.commit()
        return perfil
