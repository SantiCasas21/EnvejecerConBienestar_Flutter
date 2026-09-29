"""Blueprint de Juegos (Actividad Cognitiva)."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.juego_service import JuegoService
from app.schemas.actividad_cognitiva_schema import ActividadCognitivaSchema

bp = Blueprint('juegos', __name__)
schema_many = ActividadCognitivaSchema(many=True)
schema_one = ActividadCognitivaSchema()

@bp.route('/puntaje', methods=['POST'])
@jwt_required()
def guardar_puntaje():
    """Guarda un nuevo puntaje."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'tipo_juego' not in data or 'puntaje' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    actividad = JuegoService.guardar_puntaje(data, usuario_id)
    return jsonify(schema_one.dump(actividad)), 201

@bp.route('/historial', methods=['GET'])
@jwt_required()
def get_historial():
    """Obtiene el historial de puntajes del usuario."""
    usuario_id = int(get_jwt_identity())
    limite = request.args.get('limite', default=20, type=int)
    historial = JuegoService.get_historial(usuario_id, limite=limite)
    return jsonify(schema_many.dump(historial)), 200

@bp.route('/mejores', methods=['GET'])
@jwt_required()
def get_mejores():
    """Obtiene el Top 3 (o personalizado) de mejores puntajes con copas."""
    usuario_id = int(get_jwt_identity())
    tipo_juego = request.args.get('tipo_juego')
    limite = request.args.get('limite', default=3, type=int)
    mejores = JuegoService.get_mejores_puntajes(usuario_id, tipo_juego=tipo_juego, limite=limite)
    return jsonify(schema_many.dump(mejores)), 200

@bp.route('/estadisticas', methods=['GET'])
@jwt_required()
def get_estadisticas():
    """Obtiene estadísticas globales del jugador (puntos totales, partidas, récord)."""
    usuario_id = int(get_jwt_identity())
    stats = JuegoService.get_estadisticas(usuario_id)
    return jsonify(stats), 200
