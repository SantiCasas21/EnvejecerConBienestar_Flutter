import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/mensaje_ia_model.dart';

final asistenteRepositoryProvider = Provider<AsistenteRepository>((ref) {
  return AsistenteRepository(ref.watch(apiClientProvider));
});

class ChatRespuestaResult {
  final MensajeIaModel mensajeUsuario;
  final MensajeIaModel respuestaAsistente;
  final List<String> entidadesActualizadas;

  const ChatRespuestaResult({
    required this.mensajeUsuario,
    required this.respuestaAsistente,
    required this.entidadesActualizadas,
  });
}

class ConfirmacionAccionResult {
  final String mensajeEstado;
  final MensajeIaModel mensajeActualizado;
  final List<String> entidadesActualizadas;

  const ConfirmacionAccionResult({
    required this.mensajeEstado,
    required this.mensajeActualizado,
    required this.entidadesActualizadas,
  });
}

class AsistenteRepository {
  final Dio _dio;

  AsistenteRepository(this._dio);

  Future<List<MensajeIaModel>> getHistorial({int? pacienteId}) async {
    final response = await _dio.get(
      '${ApiEndpoints.asistente}/historial',
      queryParameters: {
        if (pacienteId != null) 'paciente_id': pacienteId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final lista = (data['mensajes'] as List?) ?? [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map(MensajeIaModel.fromJson)
        .toList();
  }

  Future<ChatRespuestaResult> enviarMensaje(
    String mensaje, {
    int? pacienteId,
  }) async {
    final response = await _dio.post(
      '${ApiEndpoints.asistente}/chat',
      queryParameters: {
        if (pacienteId != null) 'paciente_id': pacienteId,
      },
      data: {
        'mensaje': mensaje,
        if (pacienteId != null) 'paciente_id': pacienteId,
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    final data = response.data as Map<String, dynamic>;
    final entidades = ((data['entidades_actualizadas'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return ChatRespuestaResult(
      mensajeUsuario: MensajeIaModel.fromJson(
        Map<String, dynamic>.from(data['usuario_mensaje'] as Map),
      ),
      respuestaAsistente: MensajeIaModel.fromJson(
        Map<String, dynamic>.from(data['respuesta_asistente'] as Map),
      ),
      entidadesActualizadas: entidades,
    );
  }

  Future<ConfirmacionAccionResult> confirmarAccion({
    required int mensajeId,
    required bool aceptar,
    int? pacienteId,
  }) async {
    final response = await _dio.post(
      '${ApiEndpoints.asistente}/confirmar-accion',
      queryParameters: {
        if (pacienteId != null) 'paciente_id': pacienteId,
      },
      data: {
        'mensaje_id': mensajeId,
        'aceptar': aceptar,
        if (pacienteId != null) 'paciente_id': pacienteId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final entidades = ((data['entidades_actualizadas'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return ConfirmacionAccionResult(
      mensajeEstado: data['msg']?.toString() ?? 'Actualizado',
      mensajeActualizado: MensajeIaModel.fromJson(
        Map<String, dynamic>.from(data['mensaje'] as Map),
      ),
      entidadesActualizadas: entidades,
    );
  }

  Future<void> limpiarHistorial({int? pacienteId}) async {
    await _dio.delete(
      '${ApiEndpoints.asistente}/historial',
      queryParameters: {
        if (pacienteId != null) 'paciente_id': pacienteId,
      },
    );
  }
}
