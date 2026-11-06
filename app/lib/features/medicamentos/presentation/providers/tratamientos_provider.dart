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

  Future<void> updateTratamiento(dynamic id, Map<String, dynamic> data) async {
    final idNum = int.tryParse(id.toString()) ?? 0;
    final updated = await ref.read(tratamientoRepositoryProvider).updateTratamiento(idNum, data);
    final current = state.value ?? [];
    final updatedList = current.map((t) {
      final tId = int.tryParse(t.id.toString()) ?? 0;
      return tId == idNum ? updated : t;
    }).toList();
    state = AsyncValue.data(updatedList);
    ref.invalidate(medicamentosNotifierProvider);
  }

  Future<void> cambiarEstado(dynamic id, String nuevoEstado) async {
    final idNum = int.tryParse(id.toString()) ?? 0;
    final updated = await ref.read(tratamientoRepositoryProvider).cambiarEstado(idNum, nuevoEstado);
    final current = state.value ?? [];
    final updatedList = current.map((t) {
      final tId = int.tryParse(t.id.toString()) ?? 0;
      return tId == idNum ? updated : t;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

  Future<void> deleteTratamiento(dynamic id) async {
    final idNum = int.tryParse(id.toString()) ?? 0;
    await ref.read(tratamientoRepositoryProvider).deleteTratamiento(idNum);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((t) {
      final tId = int.tryParse(t.id.toString()) ?? 0;
      return tId != idNum;
    }).toList());
    ref.invalidate(medicamentosNotifierProvider);
  }
}
