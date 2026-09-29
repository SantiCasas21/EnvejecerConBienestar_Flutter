"""Blueprint de Contactos."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.contacto_service import ContactoService
from app.schemas.contacto_schema import ContactoSchema

bp = Blueprint('contactos', __name__)
schema_many = ContactoSchema(many=True)
schema_one = ContactoSchema()

@bp.route('', methods=['GET'])
@jwt_required()
def get_contactos():
    """Obtiene todos los contactos del usuario."""
    usuario_id = int(get_jwt_identity())
    contactos = ContactoService.get_all(usuario_id)
    return jsonify(schema_many.dump(contactos)), 200

@bp.route('', methods=['POST'])
@jwt_required()
def create_contacto():
    """Crea un nuevo contacto."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'nombre' not in data or 'telefono' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    contacto = ContactoService.create(data, usuario_id)
    return jsonify(schema_one.dump(contacto)), 201

@bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def get_contacto(id):
    """Obtiene un contacto por ID."""
    usuario_id = int(get_jwt_identity())
    contacto = ContactoService.get_by_id(id, usuario_id)
    
    if not contacto:
        return jsonify({"msg": "Contacto no encontrado"}), 404
        
    return jsonify(schema_one.dump(contacto)), 200

@bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_contacto(id):
    """Actualiza un contacto."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    contacto = ContactoService.update(id, data, usuario_id)
    if not contacto:
        return jsonify({"msg": "Contacto no encontrado"}), 404
        
    return jsonify(schema_one.dump(contacto)), 200

@bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_contacto(id):
    """Elimina un contacto."""
    usuario_id = int(get_jwt_identity())
    success = ContactoService.delete(id, usuario_id)
    
    if not success:
        return jsonify({"msg": "Contacto no encontrado"}), 404
        
    return '', 204

@bp.route('/emergencia', methods=['GET'])
@jwt_required()
def get_contactos_emergencia():
    """Obtiene los contactos de emergencia del usuario."""
    usuario_id = int(get_jwt_identity())
    contactos = ContactoService.get_emergencia(usuario_id)
    return jsonify(schema_many.dump(contactos)), 200
