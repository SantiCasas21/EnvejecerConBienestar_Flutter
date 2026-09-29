"""Servicio de Medicamentos."""
from app.models.medicamento import Medicamento
from app.extensions import db
from typing import List, Optional, Dict, Any

class MedicamentoService:
    """Servicios para la entidad Medicamento."""

    @staticmethod
    def get_all(usuario_id: int, tratamiento_id: Optional[int] = None) -> List[Medicamento]:
        """Obtiene todos los medicamentos de un usuario, opcionalmente filtrados por tratamiento."""
        query = Medicamento.query.filter_by(usuario_id=usuario_id)
        if tratamiento_id is not None:
            query = query.filter_by(tratamiento_id=tratamiento_id)
        return query.order_by(Medicamento.esta_tomado.asc(), Medicamento.id.asc()).all()

    @staticmethod
    def get_by_id(id: int, usuario_id: int) -> Optional[Medicamento]:
        """Obtiene un medicamento específico por ID y usuario."""
        return Medicamento.query.filter_by(id=id, usuario_id=usuario_id).first()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Medicamento:
        """Crea un nuevo medicamento asegurando filtrado estricto de columnas válidas."""
        columnas_validas = {c.name for c in Medicamento.__table__.columns}
        datos_filtrados = {k: v for k, v in data.items() if k in columnas_validas}
        
        medicamento = Medicamento(usuario_id=usuario_id, **datos_filtrados)
        db.session.add(medicamento)
        db.session.commit()
        return medicamento

    @staticmethod
    def update(id: int, data: Dict[str, Any], usuario_id: int) -> Optional[Medicamento]:
        """Actualiza un medicamento existente."""
        medicamento = MedicamentoService.get_by_id(id, usuario_id)
        if not medicamento:
            return None
        
        columnas_validas = {c.name for c in Medicamento.__table__.columns}
        for key, value in data.items():
            if key in columnas_validas and hasattr(medicamento, key):
                setattr(medicamento, key, value)
                
        db.session.commit()
        return medicamento

    @staticmethod
    def delete(id: int, usuario_id: int) -> bool:
        """Elimina un medicamento."""
        medicamento = MedicamentoService.get_by_id(id, usuario_id)
        if not medicamento:
            return False
            
        db.session.delete(medicamento)
        db.session.commit()
        return True

    @staticmethod
    def toggle_tomado(id: int, usuario_id: int) -> Optional[Medicamento]:
        """Alterna el estado de 'esta_tomado' del medicamento y descuenta o repone el inventario."""
        medicamento = MedicamentoService.get_by_id(id, usuario_id)
        if not medicamento:
            return None
            
        medicamento.esta_tomado = not medicamento.esta_tomado

        # Gestión automática del inventario de pastillas
        if medicamento.esta_tomado:
            if medicamento.cantidad_restante is not None and medicamento.cantidad_restante > 0:
                medicamento.cantidad_restante -= 1
        else:
            if medicamento.cantidad_restante is not None:
                medicamento.cantidad_restante += 1

        db.session.commit()
        return medicamento

    @staticmethod
    def reabastecer(id: int, cantidad: int, usuario_id: int) -> Optional[Medicamento]:
        """Reabastece el stock sumando pastillas a la cantidad restante."""
        medicamento = MedicamentoService.get_by_id(id, usuario_id)
        if not medicamento:
            return None
            
        if medicamento.cantidad_restante is None:
            medicamento.cantidad_restante = 0
            
        medicamento.cantidad_restante += max(0, cantidad)
        db.session.commit()
        return medicamento
