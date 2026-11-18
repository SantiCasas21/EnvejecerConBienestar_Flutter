import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/contacto_model.dart';
import '../../data/repositories/contacto_repository.dart';

part 'contactos_provider.g.dart';

@riverpod
class ContactosNotifier extends _$ContactosNotifier {
  @override
  Future<List<Contacto>> build() async {
    return ref.watch(contactoRepositoryProvider).getContactos();
  }

  Future<void> addContacto(Map<String, dynamic> data) async {
    final newContacto = await ref
        .read(contactoRepositoryProvider)
        .createContacto(data);
    state = AsyncValue.data([newContacto, ...?state.value]);
  }

  Future<void> updateContacto(int id, Map<String, dynamic> data) async {
    final updated = await ref
        .read(contactoRepositoryProvider)
        .updateContacto(id, data);
    state = AsyncValue.data(
      state.value?.map((c) => c.id == id ? updated : c).toList() ?? [],
    );
  }

  Future<void> deleteContacto(int id) async {
    await ref.read(contactoRepositoryProvider).deleteContacto(id);
    state = AsyncValue.data(
      state.value?.where((c) => c.id != id).toList() ?? [],
    );
  }

  Future<Map<String, int>> sincronizarDesdeTelefono(List<Map<String, dynamic>> contactos) async {
    final res = await ref.read(contactoRepositoryProvider).sincronizarContactos(contactos);
    final creados = (res['creados'] as List<Contacto>?) ?? [];
    if (creados.isNotEmpty) {
      state = AsyncValue.data([...creados, ...?state.value]);
    }
    return {
      'creados': (res['total_creados'] as int?) ?? creados.length,
      'omitidos': (res['omitidos_duplicados'] as int?) ?? 0,
    };
  }
}
