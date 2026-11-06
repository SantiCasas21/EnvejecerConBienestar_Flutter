import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/historial_toma_model.dart';
import '../../data/models/resumen_adherencia_model.dart';
import '../../data/repositories/historial_repository.dart';

/// Notifier para la lista de tomas históricas de medicamentos
class HistorialTomasNotifier
    extends StateNotifier<AsyncValue<List<HistorialTomaModel>>> {
  final HistorialRepository _repository;

  HistorialTomasNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    cargarTomas();
  }

  Future<void> cargarTomas({
    DateTime? desde,
    DateTime? hasta,
    int? medicamentoId,
    int? pacienteId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final tomas = await _repository.getTomas(
        desde: desde,
        hasta: hasta,
        medicamentoId: medicamentoId,
        pacienteId: pacienteId,
      );
      state = AsyncValue.data(tomas);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> registrarToma({
    required int medicamentoId,
    DateTime? fecha,
    String? horaProgramada,
    String estado = 'tomada',
    String? notas,
    int? pacienteId,
  }) async {
    try {
      final nuevaToma = await _repository.registrarToma(
        medicamentoId: medicamentoId,
        fecha: fecha,
        horaProgramada: horaProgramada,
        estado: estado,
        notas: notas,
        pacienteId: pacienteId,
      );
      if (nuevaToma != null) {
        final current = state.value ?? [];
        state = AsyncValue.data([nuevaToma, ...current]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Enum para el periodo de visualización de estadísticas
enum PeriodoEstadisticas { semanal, mensual }

final periodoEstadisticasProvider =
    StateProvider<PeriodoEstadisticas>((ref) => PeriodoEstadisticas.semanal);

/// Notifier para el resumen y métricas de adherencia
class ResumenAdherenciaNotifier
    extends StateNotifier<AsyncValue<ResumenAdherenciaModel?>> {
  final HistorialRepository _repository;

  ResumenAdherenciaNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    cargarResumen(dias: 30);
  }

  Future<void> cargarResumen({
    DateTime? desde,
    DateTime? hasta,
    int? dias,
    int? pacienteId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final resumen = await _repository.getResumenAdherencia(
        desde: desde,
        hasta: hasta,
        dias: dias,
        pacienteId: pacienteId,
      );
      state = AsyncValue.data(resumen);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Notifier para el historial cronológico de hábitos de bienestar
class HistorialHabitosNotifier
    extends StateNotifier<AsyncValue<List<HabitoHistorialModel>>> {
  final HistorialRepository _repository;

  HistorialHabitosNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    cargarHabitos();
  }

  Future<void> cargarHabitos({
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    int? pacienteId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final habitos = await _repository.getHistorialHabitos(
        desde: desde,
        hasta: hasta,
        tipo: tipo,
        pacienteId: pacienteId,
      );
      state = AsyncValue.data(habitos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ── Providers ──

final historialTomasProvider = StateNotifierProvider<HistorialTomasNotifier,
    AsyncValue<List<HistorialTomaModel>>>((ref) {
  return HistorialTomasNotifier(ref.watch(historialRepositoryProvider));
});

final resumenAdherenciaProvider = StateNotifierProvider<ResumenAdherenciaNotifier,
    AsyncValue<ResumenAdherenciaModel?>>((ref) {
  return ResumenAdherenciaNotifier(ref.watch(historialRepositoryProvider));
});

final historialHabitosProvider = StateNotifierProvider<HistorialHabitosNotifier,
    AsyncValue<List<HabitoHistorialModel>>>((ref) {
  return HistorialHabitosNotifier(ref.watch(historialRepositoryProvider));
});

/// Provider por familia para consultar resumen de un paciente específico para el cuidador
final resumenPacienteProvider =
    FutureProvider.family<ResumenAdherenciaModel, int>((ref, pacienteId) async {
  final repo = ref.watch(historialRepositoryProvider);
  return await repo.getResumenAdherencia(pacienteId: pacienteId);
});

/// Provider por familia para consultar tomas de un paciente específico para el cuidador
final tomasPacienteProvider =
    FutureProvider.family<List<HistorialTomaModel>, int>((ref, pacienteId) async {
  final repo = ref.watch(historialRepositoryProvider);
  return await repo.getTomas(pacienteId: pacienteId);
});
