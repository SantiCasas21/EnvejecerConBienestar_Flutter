import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../historial/presentation/providers/historial_provider.dart';
import '../../../historial/presentation/providers/racha_provider.dart';
import '../../../home/presentation/providers/metas_provider.dart';
import '../../../medicamentos/presentation/providers/medicamentos_provider.dart';
import '../../../medicamentos/presentation/providers/tratamientos_provider.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../data/models/mensaje_ia_model.dart';
import '../../data/repositories/asistente_repository.dart';

class AsistenteState {
  final List<MensajeIaModel> mensajes;
  final bool cargandoHistorial;
  final bool enviando;
  final bool confirmando;
  final String? error;

  const AsistenteState({
    this.mensajes = const [],
    this.cargandoHistorial = false,
    this.enviando = false,
    this.confirmando = false,
    this.error,
  });

  AsistenteState copyWith({
    List<MensajeIaModel>? mensajes,
    bool? cargandoHistorial,
    bool? enviando,
    bool? confirmando,
    String? error,
    bool limpiarError = false,
  }) {
    return AsistenteState(
      mensajes: mensajes ?? this.mensajes,
      cargandoHistorial: cargandoHistorial ?? this.cargandoHistorial,
      enviando: enviando ?? this.enviando,
      confirmando: confirmando ?? this.confirmando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

final asistenteNotifierProvider = StateNotifierProvider.autoDispose
    .family<AsistenteNotifier, AsistenteState, int?>((ref, pacienteId) {
  return AsistenteNotifier(
    ref,
    ref.watch(asistenteRepositoryProvider),
    pacienteId: pacienteId,
  );
});

class AsistenteNotifier extends StateNotifier<AsistenteState> {
  final Ref _ref;
  final AsistenteRepository _repository;
  final int? pacienteId;

  AsistenteNotifier(
    this._ref,
    this._repository, {
    this.pacienteId,
  }) : super(const AsistenteState()) {
    cargarHistorial();
  }

  void _sincronizarEntidades(List<String> entidades) {
    if (entidades.isEmpty) return;
    if (entidades.contains('medicamentos')) {
      _ref.invalidate(medicamentosNotifierProvider);
      _ref.invalidate(rachaNotifierProvider);
    }
    if (entidades.contains('tratamientos')) {
      _ref.invalidate(tratamientosNotifierProvider);
    }
    if (entidades.contains('metas')) {
      _ref.invalidate(metasNotifierProvider);
      _ref.invalidate(rachaNotifierProvider);
    }
    if (entidades.contains('perfil')) {
      _ref.invalidate(perfilNotifierProvider);
    }
    if (entidades.contains('historial')) {
      _ref.invalidate(historialTomasProvider);
      _ref.invalidate(resumenAdherenciaProvider);
      _ref.invalidate(historialHabitosProvider);
      _ref.invalidate(rachaNotifierProvider);
    }
  }

  Future<void> cargarHistorial() async {
    state = state.copyWith(cargandoHistorial: true, limpiarError: true);
    try {
      final mensajes = await _repository.getHistorial(pacienteId: pacienteId);
      state = state.copyWith(mensajes: mensajes, cargandoHistorial: false);
    } catch (e) {
      state = state.copyWith(
        cargandoHistorial: false,
        error: 'No se pudo cargar la conversación anterior.',
      );
    }
  }

  Future<void> enviarMensaje(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || state.enviando) return;

    final optimista = MensajeIaModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      rol: 'user',
      contenido: limpio,
    );

    state = state.copyWith(
      mensajes: [...state.mensajes, optimista],
      enviando: true,
      limpiarError: true,
    );

    try {
      final res = await _repository.enviarMensaje(limpio, pacienteId: pacienteId);
      final sinOptimista =
          state.mensajes.where((m) => m.id != optimista.id).toList();
      state = state.copyWith(
        mensajes: [...sinOptimista, res.mensajeUsuario, res.respuestaAsistente],
        enviando: false,
      );
      _sincronizarEntidades(res.entidadesActualizadas);
    } catch (e) {
      final sinOptimista =
          state.mensajes.where((m) => m.id != optimista.id).toList();
      state = state.copyWith(
        mensajes: sinOptimista,
        enviando: false,
        error: 'No pude responder en este momento. Verifica tu conexión e inténtalo de nuevo.',
      );
    }
  }

  Future<void> confirmarAccion(int mensajeId, bool aceptar) async {
    if (state.confirmando) return;
    state = state.copyWith(confirmando: true, limpiarError: true);
    try {
      final res = await _repository.confirmarAccion(
        mensajeId: mensajeId,
        aceptar: aceptar,
        pacienteId: pacienteId,
      );
      final actualizados = state.mensajes
          .map((m) => m.id == mensajeId ? res.mensajeActualizado : m)
          .toList();
      state = state.copyWith(mensajes: actualizados, confirmando: false);
      _sincronizarEntidades(res.entidadesActualizadas);
    } catch (e) {
      state = state.copyWith(
        confirmando: false,
        error: 'No se pudo completar la confirmación. Intenta nuevamente.',
      );
    }
  }

  Future<void> reiniciarConversacion() async {
    state = state.copyWith(cargandoHistorial: true, limpiarError: true);
    try {
      await _repository.limpiarHistorial(pacienteId: pacienteId);
      state = state.copyWith(mensajes: const [], cargandoHistorial: false);
    } catch (e) {
      state = state.copyWith(
        cargandoHistorial: false,
        error: 'No se pudo reiniciar la conversación.',
      );
    }
  }
}
