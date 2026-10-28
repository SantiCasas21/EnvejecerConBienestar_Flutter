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
    def _coerce_tipos(data: Dict[str, Any]) -> Dict[str, Any]:
        """Convierte cadenas ISO a time o date si es necesario para SQLAlchemy SQLite."""
        from datetime import datetime as dt
        res = dict(data)
        if 'hora_alarma' in res and isinstance(res['hora_alarma'], str):
            try:
                res['hora_alarma'] = dt.strptime(res['hora_alarma'], '%H:%M').time()
            except Exception:
                try:
                    res['hora_alarma'] = dt.strptime(res['hora_alarma'], '%H:%M:%S').time()
                except Exception:
                    pass
        if 'fecha_inicio' in res and isinstance(res['fecha_inicio'], str):
            try:
                res['fecha_inicio'] = dt.strptime(res['fecha_inicio'], '%Y-%m-%d').date()
            except Exception:
                pass
        return res

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Medicamento:
        """Crea un nuevo medicamento asegurando filtrado estricto de columnas válidas."""
        columnas_validas = {c.name for c in Medicamento.__table__.columns}
        datos_coercionados = MedicamentoService._coerce_tipos(data)
        datos_filtrados = {k: v for k, v in datos_coercionados.items() if k in columnas_validas}
        
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
        datos_coercionados = MedicamentoService._coerce_tipos(data)
        for key, value in datos_coercionados.items():
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

        # Gestión automática del inventario de pastillas y registro histórico
        from app.services.historial_service import HistorialService
        if medicamento.esta_tomado:
            if medicamento.cantidad_restante is not None and medicamento.cantidad_restante > 0:
                medicamento.cantidad_restante -= 1
            HistorialService.registrar_toma(
                usuario_id=usuario_id,
                medicamento_id=medicamento.id,
                estado='tomada'
            )
        else:
            if medicamento.cantidad_restante is not None:
                medicamento.cantidad_restante += 1
            HistorialService.eliminar_toma_hoy(
                usuario_id=usuario_id,
                medicamento_id=medicamento.id
            )

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
