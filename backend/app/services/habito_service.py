"""Servicio de Habitos."""
from app.models.habito import Habito
from app.extensions import db
from datetime import date
from typing import List, Optional, Dict, Any

class HabitoService:
    """Servicios para la entidad Habito."""

    @staticmethod
    def get_by_fecha(usuario_id: int, fecha: date) -> List[Habito]:
        """Obtiene los hábitos de un usuario para una fecha específica."""
        return Habito.query.filter_by(usuario_id=usuario_id, fecha=fecha).all()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Habito:
        """Crea un nuevo hábito."""
        habito = Habito(usuario_id=usuario_id, **data)
        db.session.add(habito)
        db.session.commit()
        return habito

    @staticmethod
    def actualizar_progreso(id: int, valor: int, usuario_id: int) -> Optional[Habito]:
        """Actualiza el progreso de un hábito."""
        habito = Habito.query.filter_by(id=id, usuario_id=usuario_id).first()
        if not habito:
            return None
            
        habito.progreso_actual = valor
        db.session.commit()
        return habito

    @staticmethod
    def inicializar_habitos_default(usuario_id: int, fecha: date) -> List[Habito]:
        """Inicializa hábitos por defecto para un nuevo usuario en una fecha."""
        habitos_default = [
            {"tipo": "Agua", "meta": 8, "progreso_actual": 0},
            {"tipo": "Caminata", "meta": 30, "progreso_actual": 0}
        ]
        
        creados = []
        for h in habitos_default:
            habito = Habito(usuario_id=usuario_id, fecha=fecha, **h)
            db.session.add(habito)
            creados.append(habito)
            
        db.session.commit()
        return creados
