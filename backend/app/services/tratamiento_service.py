"""Servicio de Tratamientos Médicos."""
from app.models.tratamiento import Tratamiento
from app.models.medicamento import Medicamento
from app.extensions import db
from typing import List, Optional, Dict, Any

class TratamientoService:
    """Servicios de negocio para la gestión de Tratamientos."""

    @staticmethod
    def get_all(usuario_id: int, estado: Optional[str] = None) -> List[Tratamiento]:
        """Obtiene todos los tratamientos del usuario, filtrados opcionalmente por estado."""
        query = Tratamiento.query.filter_by(usuario_id=usuario_id)
        if estado:
            query = query.filter_by(estado=estado)
        return query.order_by(Tratamiento.id.desc()).all()

    @staticmethod
    def get_by_id(id: int, usuario_id: int) -> Optional[Tratamiento]:
        """Obtiene un tratamiento específico por ID y usuario."""
        return Tratamiento.query.filter_by(id=id, usuario_id=usuario_id).first()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Tratamiento:
        """Crea un nuevo tratamiento clínico y vincula medicamentos opcionales."""
        medicamento_ids = data.pop('medicamento_ids', None)
        
        columnas_validas = {c.name for c in Tratamiento.__table__.columns}
        datos_filtrados = {k: v for k, v in data.items() if k in columnas_validas}
        
        tratamiento = Tratamiento(usuario_id=usuario_id, **datos_filtrados)
        db.session.add(tratamiento)
        db.session.flush()  # Obtener tratamiento.id
        
        if medicamento_ids and isinstance(medicamento_ids, list):
            for med_id in medicamento_ids:
                med = Medicamento.query.filter_by(id=med_id, usuario_id=usuario_id).first()
                if med:
                    med.tratamiento_id = tratamiento.id
                    
        db.session.commit()
        return tratamiento

    @staticmethod
    def update(id: int, data: Dict[str, Any], usuario_id: int) -> Optional[Tratamiento]:
        """Actualiza un tratamiento existente."""
        tratamiento = TratamientoService.get_by_id(id, usuario_id)
        if not tratamiento:
            return None
            
        medicamento_ids = data.pop('medicamento_ids', None)
        columnas_validas = {c.name for c in Tratamiento.__table__.columns}
        for key, value in data.items():
            if key in columnas_validas and hasattr(tratamiento, key):
                setattr(tratamiento, key, value)

        if medicamento_ids is not None and isinstance(medicamento_ids, list):
            # Desvincular los previos
            Medicamento.query.filter_by(tratamiento_id=tratamiento.id, usuario_id=usuario_id).update({"tratamiento_id": None})
            # Vincular los nuevos
            for med_id in medicamento_ids:
                med = Medicamento.query.filter_by(id=med_id, usuario_id=usuario_id).first()
                if med:
                    med.tratamiento_id = tratamiento.id
                    
        db.session.commit()
        return tratamiento

    @staticmethod
    def cambiar_estado(id: int, nuevo_estado: str, usuario_id: int) -> Optional[Tratamiento]:
        """Cambia el estado de un tratamiento ('activo', 'completado', 'suspendido')."""
        tratamiento = TratamientoService.get_by_id(id, usuario_id)
        if not tratamiento:
            return None
            
        tratamiento.estado = nuevo_estado
        db.session.commit()
        return tratamiento

    @staticmethod
    def delete(id: int, usuario_id: int) -> bool:
        """Elimina un tratamiento y desvincula sus medicamentos."""
        tratamiento = TratamientoService.get_by_id(id, usuario_id)
        if not tratamiento:
            return False
            
        # Desvincular medicamentos para no dejarlos huérfanos o eliminarlos por cascada
        Medicamento.query.filter_by(tratamiento_id=tratamiento.id, usuario_id=usuario_id).update({"tratamiento_id": None})
        
        db.session.delete(tratamiento)
        db.session.commit()
        return True
