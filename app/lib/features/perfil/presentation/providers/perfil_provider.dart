import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/perfil_model.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../../contactos/presentation/providers/contactos_provider.dart';

part 'perfil_provider.g.dart';

@riverpod
class PerfilNotifier extends _$PerfilNotifier {
  @override
  Future<PerfilModel?> build() async {
    return ref.watch(perfilRepositoryProvider).getPerfil();
  }

  Future<void> guardarPerfil(Map<String, dynamic> data) async {
    final updated = await ref
        .read(perfilRepositoryProvider)
        .guardarPerfil(data);
    state = AsyncValue.data(updated);
    ref.invalidate(contactosNotifierProvider);
  }

  void actualizarPerfil(PerfilModel perfil) {
    state = AsyncValue.data(perfil);
    ref.invalidate(contactosNotifierProvider);
  }
}
