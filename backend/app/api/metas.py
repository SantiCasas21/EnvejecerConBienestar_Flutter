"""Blueprint de la API de Metas."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.meta_service import MetaService
from app.schemas.meta_schema import MetaSchema, MetaCreateSchema

bp = Blueprint('metas', __name__)
schema_many = MetaSchema(many=True)
schema_one = MetaSchema()
create_schema = MetaCreateSchema()

@bp.route('', methods=['GET'])
@jwt_required()
def get_metas():
    """Obtiene todas las metas del usuario autenticado."""
    usuario_id = int(get_jwt_identity())
    metas = MetaService.get_all(usuario_id)
    return jsonify(schema_many.dump(metas)), 200

@bp.route('', methods=['POST'])
@jwt_required()
def create_meta():
    """Crea una nueva meta."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    
    errors = create_schema.validate(data)
    if errors:
        return jsonify({"msg": "Error de validación", "errores": errors}), 400
        
    meta = MetaService.create(data, usuario_id)
    return jsonify(schema_one.dump(meta)), 201

@bp.route('/<int:id>/progreso', methods=['PATCH'])
@jwt_required()
def incrementar_progreso(id):
    """Incrementa el progreso de una meta."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    valor = data.get('valor', 1)
    
    meta = MetaService.incrementar_progreso(id, valor, usuario_id)
    if not meta:
        return jsonify({"msg": "Meta no encontrada"}), 404
        
    return jsonify(schema_one.dump(meta)), 200

@bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_meta(id):
    """Elimina una meta."""
    usuario_id = int(get_jwt_identity())
    if MetaService.delete(id, usuario_id):
        return '', 204
    return jsonify({"msg": "Meta no encontrada"}), 404
