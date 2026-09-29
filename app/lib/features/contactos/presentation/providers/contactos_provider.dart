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
}
