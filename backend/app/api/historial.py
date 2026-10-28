"""Blueprint de Historial y Hábitos de Bienestar."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from app.extensions import db
from app.services.historial_service import HistorialService
from app.schemas.historial_toma_schema import HistorialTomaSchema, HistorialTomaCreateSchema

bp = Blueprint('historial', __name__)
schema_many = HistorialTomaSchema(many=True)
schema_one = HistorialTomaSchema()
create_schema = HistorialTomaCreateSchema()

def _parse_date(date_str):
    if not date_str:
        return None
    try:
        return datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return None

@bp.route('/tomas', methods=['GET'])
@jwt_required()
def listar_tomas():
    """
    Lista el historial de tomas de medicamentos con filtros opcionales.
    Query params: desde (YYYY-MM-DD), hasta (YYYY-MM-DD), medicamento_id, paciente_id.
    """
    usuario_id = int(get_jwt_identity())
    desde = _parse_date(request.args.get('desde'))
    hasta = _parse_date(request.args.get('hasta'))
    
    med_id_raw = request.args.get('medicamento_id')
    medicamento_id = int(med_id_raw) if med_id_raw and med_id_raw.isdigit() else None
    
    paciente_id_raw = request.args.get('paciente_id')
    paciente_id = int(paciente_id_raw) if paciente_id_raw and paciente_id_raw.isdigit() else None

    try:
        tomas = HistorialService.obtener_historial(
            usuario_id=usuario_id,
            fecha_inicio=desde,
            fecha_fin=hasta,
            medicamento_id=medicamento_id,
            paciente_id=paciente_id,
        )
        return jsonify(schema_many.dump(tomas)), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except Exception as e:
        return jsonify({"msg": f"Error al consultar tomas: {str(e)}"}), 500

@bp.route('/tomas', methods=['POST'])
@jwt_required()
def registrar_toma():
    """
    Registra o actualiza el estado de una toma de medicamento.
    """
    usuario_id = int(get_jwt_identity())
    data = request.get_json() or {}

    errors = create_schema.validate(data)
    if errors:
        return jsonify({"msg": "Error de validación", "errores": errors}), 400

    try:
        registro = HistorialService.registrar_toma(
            usuario_id=usuario_id,
            medicamento_id=data.get('medicamento_id'),
            fecha=data.get('fecha'),
            hora_programada=data.get('hora_programada'),
            estado=data.get('estado', 'tomada'),
            notas=data.get('notas'),
            paciente_id=data.get('paciente_id'),
        )
        return jsonify(schema_one.dump(registro)), 201
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except LookupError as le:
        return jsonify({"msg": str(le)}), 404
    except Exception as e:
        db.session.rollback()
        return jsonify({"msg": f"Error al registrar toma: {str(e)}"}), 500

@bp.route('/resumen', methods=['GET'])
@jwt_required()
def resumen_adherencia():
    """
    Calcula y entrega el resumen de adherencia para el usuario o paciente supervisado.
    Query params: desde (YYYY-MM-DD), hasta (YYYY-MM-DD), paciente_id.
    """
    usuario_id = int(get_jwt_identity())
    desde = _parse_date(request.args.get('desde'))
    hasta = _parse_date(request.args.get('hasta'))
    
    paciente_id_raw = request.args.get('paciente_id')
    paciente_id = int(paciente_id_raw) if paciente_id_raw and paciente_id_raw.isdigit() else None

    try:
        resumen = HistorialService.obtener_resumen_adherencia(
            usuario_id=usuario_id,
            fecha_inicio=desde,
            fecha_fin=hasta,
            paciente_id=paciente_id,
        )
        return jsonify(resumen), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except Exception as e:
        return jsonify({"msg": f"Error al calcular resumen de adherencia: {str(e)}"}), 500

@bp.route('/habitos', methods=['GET'])
@jwt_required()
def historial_habitos():
    """
    Entrega el historial de hábitos de bienestar (agua, pasos, etc.).
    Query params: desde (YYYY-MM-DD), hasta (YYYY-MM-DD), tipo, paciente_id.
    """
    usuario_id = int(get_jwt_identity())
    desde = _parse_date(request.args.get('desde'))
    hasta = _parse_date(request.args.get('hasta'))
    tipo = request.args.get('tipo')
    
    paciente_id_raw = request.args.get('paciente_id')
    paciente_id = int(paciente_id_raw) if paciente_id_raw and paciente_id_raw.isdigit() else None

    try:
        habitos = HistorialService.obtener_historial_habitos(
            usuario_id=usuario_id,
            fecha_inicio=desde,
            fecha_fin=hasta,
            tipo=tipo,
            paciente_id=paciente_id,
        )
        return jsonify(habitos), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except Exception as e:
        return jsonify({"msg": f"Error al consultar historial de hábitos: {str(e)}"}), 500
