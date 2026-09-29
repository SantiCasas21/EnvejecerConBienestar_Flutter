import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/notification_service.dart';
import '../../data/models/medicamento_model.dart';
import '../../data/repositories/medicamento_repository.dart';

part 'medicamentos_provider.g.dart';

@riverpod
class MedicamentosNotifier extends _$MedicamentosNotifier {
  List<Medicamento> _ordenar(List<Medicamento> list) {
    final sorted = List<Medicamento>.from(list);
    sorted.sort((a, b) {
      final aTomado = a.estaTomado ?? false;
      final bTomado = b.estaTomado ?? false;
      if (aTomado != bTomado) {
        return aTomado ? 1 : -1;
      }
      return (a.id is int && b.id is int) ? (a.id as int).compareTo(b.id as int) : 0;
    });
    return sorted;
  }

  @override
  Future<List<Medicamento>> build() async {
    final list = await ref.watch(medicamentoRepositoryProvider).getMedicamentos();
    return _ordenar(list);
  }

  Future<void> addMedicamento(Map<String, dynamic> data) async {
    final newMed = await ref.read(medicamentoRepositoryProvider).createMedicamento(data);
    final current = state.value ?? [];
    state = AsyncValue.data(_ordenar([newMed, ...current]));
    // Programar recordatorios automáticos
    NotificationService.programarRecordatorioMedicamento(newMed);
  }

  Future<void> toggleTomado(dynamic id) async {
    final idNum = int.tryParse(id.toString()) ?? 0;
    final updated = await ref.read(medicamentoRepositoryProvider).toggleMedicamento(idNum);
    final current = state.value ?? [];
    final updatedList = current.map((m) => m.id.toString() == id.toString() ? updated : m).toList();
    state = AsyncValue.data(_ordenar(updatedList));
  }

  Future<void> updateMedicamento(int id, Map<String, dynamic> data) async {
    final updated = await ref.read(medicamentoRepositoryProvider).updateMedicamento(id, data);
    final current = state.value ?? [];
    final updatedList = current.map((m) => m.id == id ? updated : m).toList();
    state = AsyncValue.data(_ordenar(updatedList));
    NotificationService.programarRecordatorioMedicamento(updated);
  }

  Future<void> reabastecerStock(dynamic id, int cantidad) async {
    final idNum = int.tryParse(id.toString()) ?? 0;
    final updated = await ref.read(medicamentoRepositoryProvider).reabastecerMedicamento(idNum, cantidad);
    final current = state.value ?? [];
    final updatedList = current.map((m) => m.id.toString() == id.toString() ? updated : m).toList();
    state = AsyncValue.data(_ordenar(updatedList));
  }

  Future<void> deleteMedicamento(int id) async {
    await ref.read(medicamentoRepositoryProvider).deleteMedicamento(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((m) => m.id != id).toList());
    NotificationService.cancelarNotificacion(id);
  }
}
