"""Blueprint de Medicamentos."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.medicamento_service import MedicamentoService
from app.schemas.medicamento_schema import MedicamentoSchema, MedicamentoCreateSchema

bp = Blueprint('medicamentos', __name__)
schema_many = MedicamentoSchema(many=True)
schema_one = MedicamentoSchema()
create_schema = MedicamentoCreateSchema()

@bp.route('', methods=['GET'])
@bp.route('/', methods=['GET'])
@jwt_required()
def get_medicamentos():
    """Obtiene todos los medicamentos del usuario, opcionalmente filtrados por tratamiento."""
    usuario_id = int(get_jwt_identity())
    tratamiento_id = request.args.get('tratamiento_id', type=int)
    medicamentos = MedicamentoService.get_all(usuario_id, tratamiento_id=tratamiento_id)
    return jsonify(schema_many.dump(medicamentos)), 200

@bp.route('', methods=['POST'])
@bp.route('/', methods=['POST'])
@jwt_required()
def create_medicamento():
    """Crea un nuevo medicamento."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    
    errors = create_schema.validate(data)
    if errors:
        return jsonify({"msg": "Error de validación", "errores": errors}), 400
        
    medicamento = MedicamentoService.create(data, usuario_id)
    return jsonify(schema_one.dump(medicamento)), 201

@bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def get_medicamento(id):
    """Obtiene un medicamento por ID."""
    usuario_id = int(get_jwt_identity())
    medicamento = MedicamentoService.get_by_id(id, usuario_id)
    
    if not medicamento:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return jsonify(schema_one.dump(medicamento)), 200

@bp.route('/<int:id>', methods=['PUT', 'PATCH'])
@jwt_required()
def update_medicamento(id):
    """Actualiza un medicamento."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    
    errors = create_schema.validate(data, partial=True)
    if errors:
        return jsonify({"msg": "Error de validación", "errores": errors}), 400
        
    medicamento = MedicamentoService.update(id, data, usuario_id)
    if not medicamento:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return jsonify(schema_one.dump(medicamento)), 200

@bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_medicamento(id):
    """Elimina un medicamento."""
    usuario_id = int(get_jwt_identity())
    success = MedicamentoService.delete(id, usuario_id)
    
    if not success:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return '', 204

@bp.route('/<int:id>/toggle', methods=['PATCH', 'POST'])
@bp.route('/<int:id>/toggle-tomado', methods=['PATCH', 'POST'])
@jwt_required()
def toggle_medicamento(id):
    """Alterna el estado tomado de un medicamento y actualiza inventario."""
    usuario_id = int(get_jwt_identity())
    medicamento = MedicamentoService.toggle_tomado(id, usuario_id)
    
    if not medicamento:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return jsonify(schema_one.dump(medicamento)), 200

@bp.route('/<int:id>/reabastecer', methods=['POST', 'PATCH'])
@jwt_required()
def reabastecer_medicamento(id):
    """Reabastece el stock sumando pastillas a la caja."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}
    cantidad = data.get('cantidad', 30)
    
    try:
        cantidad = int(cantidad)
    except (ValueError, TypeError):
        return jsonify({"msg": "La cantidad debe ser un número entero"}), 400
        
    medicamento = MedicamentoService.reabastecer(id, cantidad, usuario_id)
    if not medicamento:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return jsonify({
        "msg": f"Stock reabastecido exitosamente (+{cantidad} pastillas)",
        "medicamento": schema_one.dump(medicamento)
    }), 200
