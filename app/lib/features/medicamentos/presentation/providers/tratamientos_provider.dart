import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/tratamiento_model.dart';
import '../../data/repositories/tratamiento_repository.dart';
import 'medicamentos_provider.dart';

part 'tratamientos_provider.g.dart';

@riverpod
class TratamientosNotifier extends _$TratamientosNotifier {
  @override
  Future<List<TratamientoModel>> build() async {
    return ref.watch(tratamientoRepositoryProvider).getTratamientos();
  }

  Future<void> addTratamiento(Map<String, dynamic> data) async {
    final newTrat = await ref.read(tratamientoRepositoryProvider).createTratamiento(data);
    final current = state.value ?? [];
    state = AsyncValue.data([newTrat, ...current]);
    // Refrescar medicamentos porque pueden haber sido asociados al nuevo tratamiento
    ref.invalidate(medicamentosNotifierProvider);
  }

  Future<void> updateTratamiento(int id, Map<String, dynamic> data) async {
    final updated = await ref.read(tratamientoRepositoryProvider).updateTratamiento(id, data);
    final current = state.value ?? [];
    final updatedList = current.map((t) => t.id == id ? updated : t).toList();
    state = AsyncValue.data(updatedList);
    ref.invalidate(medicamentosNotifierProvider);
  }

  Future<void> cambiarEstado(int id, String nuevoEstado) async {
    final updated = await ref.read(tratamientoRepositoryProvider).cambiarEstado(id, nuevoEstado);
    final current = state.value ?? [];
    final updatedList = current.map((t) => t.id == id ? updated : t).toList();
    state = AsyncValue.data(updatedList);
  }

  Future<void> deleteTratamiento(int id) async {
    await ref.read(tratamientoRepositoryProvider).deleteTratamiento(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((t) => t.id != id).toList());
    ref.invalidate(medicamentosNotifierProvider);
  }
}
