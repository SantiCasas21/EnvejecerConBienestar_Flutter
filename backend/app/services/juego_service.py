"""Servicio de Juegos (Actividad Cognitiva)."""
from app.models.actividad_cognitiva import ActividadCognitiva
from app.extensions import db
from typing import List, Dict, Any, Optional
from sqlalchemy import func

class JuegoService:
    """Servicios para las actividades cognitivas."""

    @staticmethod
    def guardar_puntaje(data: Dict[str, Any], usuario_id: int) -> ActividadCognitiva:
        """Guarda el puntaje de un juego de manera segura."""
        tipo_juego = str(data.get('tipo_juego', 'Juego')).strip()
        puntaje = int(data.get('puntaje', 0))
        actividad = ActividadCognitiva(
            usuario_id=usuario_id,
            tipo_juego=tipo_juego,
            puntaje=puntaje,
        )
        db.session.add(actividad)
        db.session.commit()
        return actividad

    @staticmethod
    def get_historial(usuario_id: int, limite: int = 20) -> List[ActividadCognitiva]:
        """Obtiene el historial de puntajes de un usuario ordenado por fecha."""
        return (
            ActividadCognitiva.query
            .filter_by(usuario_id=usuario_id)
            .order_by(ActividadCognitiva.fecha_realizacion.desc())
            .limit(limite)
            .all()
        )

    @staticmethod
    def get_mejores_puntajes(usuario_id: int, tipo_juego: Optional[str] = None, limite: int = 3) -> List[ActividadCognitiva]:
        """Obtiene el Top de mejores puntajes del usuario (Top 1, 2, 3) general o por minijuego."""
        query = ActividadCognitiva.query.filter_by(usuario_id=usuario_id)
        if tipo_juego and tipo_juego.lower() != 'todos':
            query = query.filter(func.lower(ActividadCognitiva.tipo_juego) == tipo_juego.lower().strip())
        return (
            query
            .order_by(ActividadCognitiva.puntaje.desc(), ActividadCognitiva.fecha_realizacion.desc())
            .limit(limite)
            .all()
        )

    @staticmethod
    def get_estadisticas(usuario_id: int) -> Dict[str, Any]:
        """Obtiene resumen de puntos totales, partidas completadas y mejor récord."""
        partidas = ActividadCognitiva.query.filter_by(usuario_id=usuario_id).all()
        if not partidas:
            return {
                "total_puntos": 0,
                "partidas_jugadas": 0,
                "record_maximo": 0,
                "juego_favorito": "Ninguno aún",
            }

        total_puntos = sum(p.puntaje for p in partidas)
        partidas_jugadas = len(partidas)
        record_maximo = max(p.puntaje for p in partidas)

        # Juego favorito / más jugado
        conteo_juegos: Dict[str, int] = {}
        for p in partidas:
            conteo_juegos[p.tipo_juego] = conteo_juegos.get(p.tipo_juego, 0) + 1
        juego_favorito = max(conteo_juegos, key=conteo_juegos.get) if conteo_juegos else "Ninguno"

        return {
            "total_puntos": total_puntos,
            "partidas_jugadas": partidas_jugadas,
            "record_maximo": record_maximo,
            "juego_favorito": juego_favorito,
        }
