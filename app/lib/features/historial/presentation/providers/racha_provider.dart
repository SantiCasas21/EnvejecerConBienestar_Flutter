import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/racha_model.dart';

class RachaNotifier extends StateNotifier<AsyncValue<RachaModel>> {
  final Ref ref;

  RachaNotifier(this.ref) : super(const AsyncValue.loading()) {
    cargarRacha();
  }

  Future<void> cargarRacha({int? pacienteId}) async {
    try {
      final dio = ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{};
      if (pacienteId != null) {
        queryParams['paciente_id'] = pacienteId;
      }

      final response = await dio.get('/historial/racha', queryParameters: queryParams);
      final model = RachaModel.fromJson(response.data as Map<String, dynamic>);
      state = AsyncValue.data(model);
    } catch (_) {
      // Si falla la red, proveer un modelo local por defecto amable
      state = AsyncValue.data(
        const RachaModel(
          usuarioId: 1,
          rachaActual: 1,
          rachaMejor: 1,
          mensajeRacha: '¡Tu llama de bienestar está encendida! 🔥',
        ),
      );
    }
  }

  void celebrarAccionHoy() {
    final current = state.value;
    if (current != null && !current.hoyCompletado) {
      final nuevaRacha = current.rachaActual + 1;
      state = AsyncValue.data(
        RachaModel(
          usuarioId: current.usuarioId,
          rachaActual: nuevaRacha,
          rachaMejor: nuevaRacha > current.rachaMejor ? nuevaRacha : current.rachaMejor,
          mensajeRacha: '🔥 ¡Día completado! Tu racha sigue creciendo con fuerza.',
          diasSemana: current.diasSemana.map((d) => d.esHoy ? DiaSemanaRacha(letra: d.letra, fecha: d.fecha, activo: true, esHoy: true) : d).toList(),
          hoyCompletado: true,
        ),
      );
    }
  }
}

final rachaNotifierProvider = StateNotifierProvider<RachaNotifier, AsyncValue<RachaModel>>((ref) {
  return RachaNotifier(ref);
});
