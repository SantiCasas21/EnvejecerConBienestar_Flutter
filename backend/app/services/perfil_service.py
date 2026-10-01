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

        # Sincronización automática con la libreta de contactos (Contacto de Emergencia SOS)
        tel_emergencia = data.get('contacto_emergencia_telefono')
        nombre_emergencia = data.get('contacto_emergencia_nombre')
        parentesco_emergencia = data.get('contacto_emergencia_parentesco') or 'Familia'

        if tel_emergencia and str(tel_emergencia).strip():
            from app.models.contacto import Contacto
            tel_limpio = str(tel_emergencia).strip()
            nom_limpio = str(nombre_emergencia).strip() if nombre_emergencia else 'Contacto de Emergencia'

            # Buscar si ya existe un contacto SOS o con el mismo teléfono para este usuario
            contacto_existente = Contacto.query.filter(
                Contacto.usuario_id == usuario_id,
                (Contacto.es_emergencia == True) | (Contacto.telefono == tel_limpio)
            ).first()

            if contacto_existente:
                contacto_existente.nombre = nom_limpio
                contacto_existente.telefono = tel_limpio
                contacto_existente.categoria = parentesco_emergencia
                contacto_existente.es_emergencia = True
                contacto_existente.es_favorito = True
                if not contacto_existente.icono or contacto_existente.icono == '👤':
                    contacto_existente.icono = '🚨'
            else:
                nuevo_contacto = Contacto(
                    usuario_id=usuario_id,
                    nombre=nom_limpio,
                    telefono=tel_limpio,
                    categoria=parentesco_emergencia,
                    es_emergencia=True,
                    es_favorito=True,
                    icono='🚨'
                )
                db.session.add(nuevo_contacto)

        db.session.commit()
        return perfil

