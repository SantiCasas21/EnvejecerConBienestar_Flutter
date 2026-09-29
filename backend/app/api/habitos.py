"""Blueprint de Hábitos."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.habito_service import HabitoService
from app.schemas.habito_schema import HabitoSchema
from datetime import datetime

bp = Blueprint('habitos', __name__)
schema_many = HabitoSchema(many=True)
schema_one = HabitoSchema()

@bp.route('', methods=['GET'])
@jwt_required()
def get_habitos():
    """Obtiene los hábitos de una fecha específica."""
    usuario_id = int(get_jwt_identity())
    fecha_str = request.args.get('fecha')
    
    if not fecha_str:
        return jsonify({"msg": "La fecha es requerida"}), 400
        
    try:
        fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({"msg": "Formato de fecha inválido. Use YYYY-MM-DD"}), 400
        
    habitos = HabitoService.get_by_fecha(usuario_id, fecha)
    return jsonify(schema_many.dump(habitos)), 200

@bp.route('', methods=['POST'])
@jwt_required()
def create_habito():
    """Crea un nuevo hábito."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'tipo' not in data or 'meta' not in data or 'fecha' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    try:
        data['fecha'] = datetime.strptime(data['fecha'], '%Y-%m-%d').date()
    except ValueError:
        return jsonify({"msg": "Formato de fecha inválido. Use YYYY-MM-DD"}), 400
        
    habito = HabitoService.create(data, usuario_id)
    return jsonify(schema_one.dump(habito)), 201

@bp.route('/<int:id>/progreso', methods=['PATCH'])
@jwt_required()
def update_progreso(id):
    """Actualiza el progreso de un hábito."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'progreso_actual' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    habito = HabitoService.actualizar_progreso(id, data['progreso_actual'], usuario_id)
    if not habito:
        return jsonify({"msg": "Hábito no encontrado"}), 404
        
    return jsonify(schema_one.dump(habito)), 200
