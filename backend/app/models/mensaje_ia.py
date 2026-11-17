"""Modelo de Mensajes del Asistente IA (Módulo 9)."""
import json
from datetime import datetime, timezone
from app.extensions import db


class MensajeIA(db.Model):
    """Entidad que almacena el historial de conversación con el Asistente de Salud IA."""
    __tablename__ = 'mensajes_ia'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False, index=True)
    paciente_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False, index=True)
    rol = db.Column(db.String(20), nullable=False)  # 'user' | 'assistant'
    contenido = db.Column(db.Text, nullable=False)
    alerta_preventiva = db.Column(db.Text, nullable=True)
    es_emergencia = db.Column(db.Boolean, default=False, nullable=False)
    accion_pendiente_json = db.Column(db.Text, nullable=True)
    entidades_actualizadas_json = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), index=True)

    def get_accion_pendiente(self) -> dict | None:
        """Deserializa la acción pendiente si existe."""
        if not self.accion_pendiente_json:
            return None
        try:
            return json.loads(self.accion_pendiente_json)
        except Exception:
            return None

    def set_accion_pendiente(self, accion: dict | None) -> None:
        """Serializa una acción pendiente a JSON."""
        self.accion_pendiente_json = json.dumps(accion, ensure_ascii=False) if accion else None

    def get_entidades_actualizadas(self) -> list:
        """Deserializa la lista de entidades actualizadas."""
        if not self.entidades_actualizadas_json:
            return []
        try:
            return json.loads(self.entidades_actualizadas_json)
        except Exception:
            return []

    def to_dict(self) -> dict:
        """Serializa el mensaje para respuesta REST."""
        return {
            'id': self.id,
            'usuario_id': self.usuario_id,
            'paciente_id': self.paciente_id,
            'rol': self.rol,
            'contenido': self.contenido,
            'alerta_preventiva': self.alerta_preventiva,
            'es_emergencia': bool(self.es_emergencia),
            'accion_pendiente': self.get_accion_pendiente(),
            'entidades_actualizadas': self.get_entidades_actualizadas(),
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
