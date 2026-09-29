import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/meta_model.dart';
import '../../data/repositories/meta_repository.dart';

part 'metas_provider.g.dart';

@riverpod
class MetasNotifier extends _$MetasNotifier {
  @override
  Future<List<MetaModel>> build() async {
    return ref.watch(metaRepositoryProvider).getMetas();
  }

  Future<void> addMeta(Map<String, dynamic> data) async {
    final newMeta = await ref.read(metaRepositoryProvider).createMeta(data);
    state = AsyncValue.data([newMeta, ...?state.value]);
  }

  Future<void> incrementarProgreso(int id) async {
    final updated = await ref
        .read(metaRepositoryProvider)
        .incrementarProgreso(id);
    state = AsyncValue.data(
      state.value?.map((m) => m.id == id ? updated : m).toList() ?? [],
    );
  }

  Future<void> deleteMeta(int id) async {
    await ref.read(metaRepositoryProvider).deleteMeta(id);
    state = AsyncValue.data(
      state.value?.where((m) => m.id != id).toList() ?? [],
    );
  }
}
