"""Blueprint de Expediente Clínico Integral y Contexto IA."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.expediente_service import ExpedienteService
from app.models.usuario import Usuario
from app.models.cuidador_paciente import CuidadorPaciente

bp = Blueprint('expediente', __name__)

def _determinar_usuario_objetivo(usuario_id: int, paciente_id_param: str | None) -> tuple[int | None, str | None, int]:
    """
    Resuelve el ID del paciente objetivo validando permisos de rol y vínculos de cuidador.

    :param usuario_id: ID del usuario autenticado en JWT.
    :param paciente_id_param: Valor opcional del query parameter ?paciente_id=
    :return: Tupla (target_id, error_msg, http_code).
    """
    user = Usuario.query.get(usuario_id)
    if not user:
        return None, "Usuario en sesión no encontrado.", 404

    # Si es adulto mayor, su expediente es siempre el suyo propio
    if user.rol != 'cuidador':
        return usuario_id, None, 200

    # Si es cuidador y especificó paciente_id
    if paciente_id_param:
        try:
            pid = int(paciente_id_param)
        except ValueError:
            return None, "El parámetro 'paciente_id' debe ser un número entero válido.", 400

        vinculo = CuidadorPaciente.query.filter_by(cuidador_id=usuario_id, paciente_id=pid).first()
        if not vinculo:
            return None, "No tienes autorización para consultar el expediente de este paciente.", 403
        return pid, None, 200

    # Si es cuidador pero no envió paciente_id, buscamos su primer paciente vinculado
    primer_vinculo = CuidadorPaciente.query.filter_by(cuidador_id=usuario_id).first()
    if not primer_vinculo:
        return None, "No tienes ningún paciente vinculado actualmente para consultar su expediente.", 404

    return primer_vinculo.paciente_id, None, 200

@bp.route('', methods=['GET'])
@bp.route('/', methods=['GET'])
@jwt_required()
def get_expediente():
    """
    Obtiene el expediente clínico completo del usuario autenticado o de un paciente supervisado.
    Soporta query param: ?paciente_id=<int> para cuidadores autorizados.
    """
    usuario_id = int(get_jwt_identity())
    paciente_id_param = request.args.get('paciente_id')

    target_id, error_msg, status_code = _determinar_usuario_objetivo(usuario_id, paciente_id_param)
    if error_msg:
        return jsonify({"msg": error_msg}), status_code

    try:
        expediente = ExpedienteService.get_expediente_completo(target_id)
        return jsonify(expediente), 200
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 404
    except Exception as e:
        return jsonify({"msg": f"Error al generar el expediente clínico: {str(e)}"}), 500

@bp.route('/contexto-ia', methods=['GET'])
@jwt_required()
def get_contexto_ia():
    """
    Genera el resumen semántico clínico formateado para el futuro Asistente IA (Módulo 9)
    con guardrails de seguridad y advertencias médicas.
    """
    usuario_id = int(get_jwt_identity())
    paciente_id_param = request.args.get('paciente_id')

    target_id, error_msg, status_code = _determinar_usuario_objetivo(usuario_id, paciente_id_param)
    if error_msg:
        return jsonify({"msg": error_msg}), status_code

    try:
        contexto_texto = ExpedienteService.get_contexto_ia(target_id)
        return jsonify({
            "paciente_id": target_id,
            "contexto_ia": contexto_texto
        }), 200
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 404
    except Exception as e:
        return jsonify({"msg": f"Error al generar el contexto para IA: {str(e)}"}), 500

@bp.route('/prediccion-adherencia-ml', methods=['GET'])
@jwt_required()
def get_prediccion_adherencia_ml():
    """
    Función de Machine Learning: Evalúa el riesgo predictivo de omisión o abandono
    terapéutico a través de un clasificador supervisado sigmoidal (GALC-v1).
    Soporta query param: ?paciente_id=<int> para cuidadores autorizados.
    """
    usuario_id = int(get_jwt_identity())
    paciente_id_param = request.args.get('paciente_id')

    target_id, error_msg, status_code = _determinar_usuario_objetivo(usuario_id, paciente_id_param)
    if error_msg:
        return jsonify({"msg": error_msg}), status_code

    try:
        resultado_ml = ExpedienteService.predecir_adherencia_ml(target_id)
        return jsonify(resultado_ml), 200
    except ValueError as ve:
        return jsonify({"msg": str(ve)}), 404
    except Exception as e:
        return jsonify({"msg": f"Error al ejecutar modelo predictivo ML: {str(e)}"}), 500

