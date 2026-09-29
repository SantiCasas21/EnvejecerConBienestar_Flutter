"""Blueprint de Tratamientos."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.tratamiento_service import TratamientoService
from app.schemas.tratamiento_schema import TratamientoSchema, TratamientoCreateSchema

bp = Blueprint('tratamientos', __name__)
schema_many = TratamientoSchema(many=True)
schema_one = TratamientoSchema()
create_schema = TratamientoCreateSchema()

@bp.route('', methods=['GET'])
@bp.route('/', methods=['GET'])
@jwt_required()
def get_tratamientos():
    """Obtiene todos los tratamientos del usuario."""
    usuario_id = int(get_jwt_identity())
    estado = request.args.get('estado')
    tratamientos = TratamientoService.get_all(usuario_id, estado=estado)
    return jsonify(schema_many.dump(tratamientos)), 200

@bp.route('', methods=['POST'])
@bp.route('/', methods=['POST'])
@jwt_required()
def create_tratamiento():
    """Crea un nuevo tratamiento."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    
    errors = create_schema.validate(data)
    if errors:
        return jsonify({"msg": "Error de validación", "errores": errors}), 400
        
    tratamiento = TratamientoService.create(data, usuario_id)
    return jsonify(schema_one.dump(tratamiento)), 201

@bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def get_tratamiento(id):
    """Obtiene el detalle de un tratamiento."""
    usuario_id = int(get_jwt_identity())
    tratamiento = TratamientoService.get_by_id(id, usuario_id)
    
    if not tratamiento:
        return jsonify({"msg": "Tratamiento no encontrado"}), 404
        
    return jsonify(schema_one.dump(tratamiento)), 200

@bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_tratamiento(id):
    """Actualiza un tratamiento."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    
    errors = create_schema.validate(data, partial=True)
    if errors:
        return jsonify({"msg": "Error de validación", "errores": errors}), 400
        
    tratamiento = TratamientoService.update(id, data, usuario_id)
    if not tratamiento:
        return jsonify({"msg": "Tratamiento no encontrado"}), 404
        
    return jsonify(schema_one.dump(tratamiento)), 200

@bp.route('/<int:id>/estado', methods=['PATCH', 'PUT'])
@jwt_required()
def cambiar_estado_tratamiento(id):
    """Cambia el estado de un tratamiento ('activo', 'completado', 'suspendido')."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    nuevo_estado = data.get('estado')
    
    if nuevo_estado not in ['activo', 'completado', 'suspendido']:
        return jsonify({"msg": "Estado inválido. Debe ser activo, completado o suspendido"}), 400
        
    tratamiento = TratamientoService.cambiar_estado(id, nuevo_estado, usuario_id)
    if not tratamiento:
        return jsonify({"msg": "Tratamiento no encontrado"}), 404
        
    return jsonify(schema_one.dump(tratamiento)), 200

@bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_tratamiento(id):
    """Elimina un tratamiento."""
    usuario_id = int(get_jwt_identity())
    success = TratamientoService.delete(id, usuario_id)
    
    if not success:
        return jsonify({"msg": "Tratamiento no encontrado"}), 404
        
    return '', 204
