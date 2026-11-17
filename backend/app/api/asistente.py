"""Blueprint del Asistente de Salud IA (Módulo 9 - DeepSeek)."""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.api.expediente import _determinar_usuario_objetivo
from app.models.usuario import Usuario
from app.services.asistente_service import AsistenteService

bp = Blueprint('asistente', __name__)


@bp.route('/chat', methods=['POST'])
@jwt_required()
def chat():
    """Envía un mensaje al Asistente IA y devuelve su respuesta con posibles acciones o alertas."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    paciente_id_param = request.args.get('paciente_id') or (
        str(data['paciente_id']) if data.get('paciente_id') is not None else None
    )

    target_id, error_msg, status_code = _determinar_usuario_objetivo(usuario_id, paciente_id_param)
    if error_msg:
        return jsonify({'msg': error_msg}), status_code

    user = Usuario.query.get(usuario_id)
    es_cuidador = bool(user and user.rol == 'cuidador')
    mensaje = data.get('mensaje', '')

    try:
        resultado = AsistenteService.procesar_mensaje(
            usuario_id=usuario_id,
            paciente_id=target_id,
            texto_usuario=mensaje,
            es_cuidador=es_cuidador,
        )
        return jsonify(resultado), 200
    except ValueError as ve:
        return jsonify({'msg': str(ve)}), 400
    except RuntimeError as re_err:
        return jsonify({'msg': str(re_err)}), 502
    except Exception as e:
        return jsonify({'msg': f'Error interno en el asistente IA: {str(e)}'}), 500


@bp.route('/confirmar-accion', methods=['POST'])
@jwt_required()
def confirmar_accion():
    """Confirma o cancela una acción clínica propuesta por el asistente IA."""
    usuario_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    paciente_id_param = request.args.get('paciente_id') or (
        str(data['paciente_id']) if data.get('paciente_id') is not None else None
    )

    target_id, error_msg, status_code = _determinar_usuario_objetivo(usuario_id, paciente_id_param)
    if error_msg:
        return jsonify({'msg': error_msg}), status_code

    mensaje_id = data.get('mensaje_id')
    if mensaje_id is None:
        return jsonify({'msg': "El campo 'mensaje_id' es obligatorio."}), 400

    aceptar = bool(data.get('aceptar', True))

    try:
        resultado = AsistenteService.confirmar_accion(
            mensaje_id=int(mensaje_id),
            paciente_id=target_id,
            aceptar=aceptar,
        )
        return jsonify(resultado), 200
    except ValueError as ve:
        return jsonify({'msg': str(ve)}), 400
    except Exception as e:
        return jsonify({'msg': f'Error al confirmar acción: {str(e)}'}), 500


@bp.route('/historial', methods=['GET'])
@jwt_required()
def get_historial():
    """Obtiene el historial conversacional del paciente con el asistente IA."""
    usuario_id = int(get_jwt_identity())
    paciente_id_param = request.args.get('paciente_id')

    target_id, error_msg, status_code = _determinar_usuario_objetivo(usuario_id, paciente_id_param)
    if error_msg:
        return jsonify({'msg': error_msg}), status_code

    mensajes = AsistenteService.obtener_historial(target_id)
    return jsonify({'paciente_id': target_id, 'mensajes': mensajes}), 200


@bp.route('/historial', methods=['DELETE'])
@jwt_required()
def delete_historial():
    """Limpia el historial conversacional para iniciar una nueva conversación."""
    usuario_id = int(get_jwt_identity())
    paciente_id_param = request.args.get('paciente_id')

    target_id, error_msg, status_code = _determinar_usuario_objetivo(usuario_id, paciente_id_param)
    if error_msg:
        return jsonify({'msg': error_msg}), status_code

    eliminados = AsistenteService.limpiar_historial(target_id)
    return jsonify({'msg': 'Conversación reiniciada.', 'eliminados': eliminados}), 200
