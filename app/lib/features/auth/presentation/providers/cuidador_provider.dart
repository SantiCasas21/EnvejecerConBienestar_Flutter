import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/paciente_vinculado_model.dart';
import '../../data/repositories/cuidador_repository.dart';
import '../../../medicamentos/data/models/medicamento_model.dart';

class CuidadorNotifier
    extends StateNotifier<AsyncValue<List<PacienteVinculadoModel>>> {
  final CuidadorRepository _repository;

  CuidadorNotifier(this._repository) : super(const AsyncValue.loading()) {
    cargarPacientes();
  }

  Future<void> cargarPacientes() async {
    state = const AsyncValue.loading();
    try {
      final pacientes = await _repository.getPacientes();
      state = AsyncValue.data(pacientes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> vincularPaciente(
    String codigoVinculacion, {
    String parentesco = 'Familiar / Cuidador',
  }) async {
    try {
      await _repository.vincularPaciente(codigoVinculacion, parentesco: parentesco);
      await cargarPacientes();
      return null; // Éxito
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return msg;
    }
  }

  Future<bool> desvincularPaciente(int pacienteId) async {
    try {
      final exito = await _repository.desvincularPaciente(pacienteId);
      if (exito) {
        final listaActual = state.value ?? [];
        state = AsyncValue.data(
          listaActual.where((p) => p.id != pacienteId).toList(),
        );
      }
      return exito;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> obtenerDetalle(int pacienteId) async {
    try {
      return await _repository.getDetallePaciente(pacienteId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> reabastecerMedicamentoPaciente(
    int pacienteId,
    int medId,
    int cantidad,
  ) async {
    final exito = await _repository.reabastecerMedicamentoPaciente(
      pacienteId,
      medId,
      cantidad,
    );
    if (exito) {
      await cargarPacientes();
    }
    return exito;
  }
}

final cuidadorNotifierProvider = StateNotifierProvider<CuidadorNotifier,
    AsyncValue<List<PacienteVinculadoModel>>>((ref) {
  final repo = ref.watch(cuidadorRepositoryProvider);
  return CuidadorNotifier(repo);
});

/// ID del paciente actualmente seleccionado por el cuidador para consultar medicamentos o botiquín.
final pacienteSeleccionadoIdProvider = StateProvider<int?>((ref) => null);

/// Provider de medicamentos en tiempo real del paciente seleccionado para el cuidador.
final medicamentosPacienteCuidadorProvider =
    FutureProvider.family<List<Medicamento>, int>((ref, pacienteId) async {
  final repo = ref.watch(cuidadorRepositoryProvider);
  final medsData = await repo.getMedicamentosPaciente(pacienteId);
  return medsData.map((json) => Medicamento.fromJson(json)).toList();
});
