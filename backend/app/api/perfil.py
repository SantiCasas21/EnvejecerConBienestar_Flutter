"""Blueprint de la API de Perfil."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.perfil_service import PerfilService
from app.schemas.perfil_schema import PerfilUsuarioSchema

bp = Blueprint('perfil', __name__)
schema_one = PerfilUsuarioSchema()

@bp.route('', methods=['GET', 'OPTIONS'])
@bp.route('/', methods=['GET', 'OPTIONS'])
@jwt_required(optional=True)
def get_perfil():
    """Obtiene el perfil del usuario autenticado."""
    if request.method == 'OPTIONS':
        return jsonify({"msg": "OK"}), 200

    identity = get_jwt_identity()
    if not identity:
        return jsonify({"msg": "Token requerido"}), 401

    usuario_id = int(identity)
    perfil = PerfilService.get_by_usuario_id(usuario_id)
    if not perfil:
        return jsonify({"perfil": None}), 200
    return jsonify(schema_one.dump(perfil)), 200

@bp.route('', methods=['PUT', 'POST'])
@bp.route('/', methods=['PUT', 'POST'])
@jwt_required()
def guardar_perfil():
    """Crea o actualiza el perfil del usuario con toda su ficha médica."""
    if request.method == 'OPTIONS':
        return jsonify({"msg": "OK"}), 200

    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    
    perfil = PerfilService.guardar_o_actualizar(data, usuario_id)
    return jsonify(schema_one.dump(perfil)), 200
