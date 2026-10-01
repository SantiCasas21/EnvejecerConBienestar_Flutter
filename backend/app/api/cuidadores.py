"""Blueprint de Gestión y Supervisión de Cuidadores."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.cuidador_service import CuidadorService

bp = Blueprint('cuidadores', __name__)

@bp.route('/vincular', methods=['POST'])
@jwt_required()
def vincular_paciente():
    """
    Vincula un paciente adulto mayor a la cuenta del cuidador autenticado.
    Espera JSON: {"codigo_vinculacion": "ECB-1001", "parentesco": "Hijo/a"}
    """
    cuidador_id = int(get_jwt_identity())
    data = request.get_json() or {}

    codigo = data.get('codigo_vinculacion', '')
    parentesco = data.get('parentesco', 'Familiar / Cuidador')

    try:
        resultado = CuidadorService.vincular_paciente(
            cuidador_id=cuidador_id,
            codigo_vinculacion=codigo,
            parentesco=parentesco
        )
        if resultado.get("ya_vinculado"):
            return jsonify(resultado), 409
        return jsonify(resultado), 201
    except LookupError as le:
        return jsonify({"msg": str(le)}), 404
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 400
    except Exception as e:
        return jsonify({"msg": f"Ocurrió un error al vincular el paciente: {str(e)}"}), 500

@bp.route('/pacientes', methods=['GET'])
@jwt_required()
def listar_pacientes():
    """
    Retorna la lista de pacientes supervisados por el cuidador autenticado
    con indicadores de tomas de hoy y alertas de stock bajo.
    """
    cuidador_id = int(get_jwt_identity())
    pacientes = CuidadorService.get_pacientes_cuidador(cuidador_id)
    return jsonify({"pacientes": pacientes}), 200

@bp.route('/pacientes/<int:paciente_id>/detalle', methods=['GET'])
@jwt_required()
def detalle_paciente(paciente_id: int):
    """
    Retorna la ficha clínica, medicamentos y estado en tiempo real del paciente.
    """
    cuidador_id = int(get_jwt_identity())
    try:
        detalle = CuidadorService.get_detalle_paciente(cuidador_id, paciente_id)
        return jsonify(detalle), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 404
    except Exception as e:
        return jsonify({"msg": f"Error al consultar el detalle: {str(e)}"}), 500

@bp.route('/pacientes/<int:paciente_id>', methods=['DELETE'])
@jwt_required()
def desvincular_paciente(paciente_id: int):
    """
    Desvincula al paciente de la supervisión del cuidador autenticado.
    """
    cuidador_id = int(get_jwt_identity())
    try:
        eliminado = CuidadorService.desvincular_paciente(cuidador_id, paciente_id)
        if not eliminado:
            return jsonify({"msg": "No se encontró ningún vínculo activo con este paciente."}), 404
        return jsonify({"msg": "Paciente desvinculado exitosamente."}), 200
    except Exception as e:
        return jsonify({"msg": f"Error al desvincular al paciente: {str(e)}"}), 500

@bp.route('/pacientes/<int:paciente_id>/medicamentos', methods=['GET'])
@jwt_required()
def listar_medicamentos_paciente(paciente_id: int):
    """
    Retorna la lista completa de medicamentos e inventario del paciente
    supervisado por el cuidador autenticado.
    """
    cuidador_id = int(get_jwt_identity())
    try:
        meds = CuidadorService.get_medicamentos_paciente(cuidador_id, paciente_id)
        return jsonify({"medicamentos": meds}), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except Exception as e:
        return jsonify({"msg": f"Error al consultar medicamentos del paciente: {str(e)}"}), 500

@bp.route('/pacientes/<int:paciente_id>/medicamentos/<int:med_id>/reabastecer', methods=['POST'])
@jwt_required()
def reabastecer_medicamento_paciente(paciente_id: int, med_id: int):
    """
    Permite al cuidador autenticado reabastecer stock de un medicamento del paciente.
    Espera JSON: {"cantidad": 10}
    """
    cuidador_id = int(get_jwt_identity())
    data = request.get_json() or {}
    cantidad = data.get('cantidad', 10)

    try:
        resultado = CuidadorService.reabastecer_medicamento_paciente(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id,
            med_id=med_id,
            cantidad=int(cantidad)
        )
        return jsonify(resultado), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 400
    except Exception as e:
        return jsonify({"msg": f"Error al reabastecer medicamento: {str(e)}"}), 500

@bp.route('/pacientes/<int:paciente_id>/tratamientos', methods=['GET'])
@jwt_required()
def listar_tratamientos_paciente(paciente_id: int):
    """
    Retorna la lista completa de tratamientos médicos del paciente
    supervisado por el cuidador autenticado.
    """
    cuidador_id = int(get_jwt_identity())
    try:
        tratamientos = CuidadorService.get_tratamientos_paciente(cuidador_id, paciente_id)
        return jsonify(tratamientos), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except Exception as e:
        return jsonify({"msg": f"Error al consultar tratamientos del paciente: {str(e)}"}), 500

@bp.route('/pacientes/<int:paciente_id>/tratamientos', methods=['POST'])
@jwt_required()
def crear_tratamiento_paciente(paciente_id: int):
    """
    Permite al cuidador autenticado registrar un tratamiento clínico para su paciente supervisado.
    """
    cuidador_id = int(get_jwt_identity())
    data = request.get_json() or {}

    try:
        nuevo_tratamiento = CuidadorService.crear_tratamiento_paciente(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id,
            data=data
        )
        return jsonify(nuevo_tratamiento), 201
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 400
    except Exception as e:
        return jsonify({"msg": f"Error al crear tratamiento: {str(e)}"}), 500

@bp.route('/pacientes/<int:paciente_id>/tratamientos/<int:tratamiento_id>', methods=['PUT'])
@jwt_required()
def actualizar_tratamiento_paciente(paciente_id: int, tratamiento_id: int):
    """
    Permite al cuidador autenticado actualizar un tratamiento clínico de su paciente supervisado.
    """
    cuidador_id = int(get_jwt_identity())
    data = request.get_json() or {}

    try:
        tratamiento_actualizado = CuidadorService.actualizar_tratamiento_paciente(
            cuidador_id=cuidador_id,
            paciente_id=paciente_id,
            tratamiento_id=tratamiento_id,
            data=data
        )
        return jsonify(tratamiento_actualizado), 200
    except PermissionError as pe:
        return jsonify({"msg": str(pe)}), 403
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 404
    except Exception as e:
        return jsonify({"msg": f"Error al actualizar tratamiento: {str(e)}"}), 500


