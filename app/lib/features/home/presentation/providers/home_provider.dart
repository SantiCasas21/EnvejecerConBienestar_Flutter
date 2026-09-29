import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/models/habito_model.dart';
import '../../../../core/utils/date_utils.dart';

class HomeState {
  final String saludo;
  final List<Habito> habitos;
  final bool isLoading;

  const HomeState({
    required this.saludo,
    required this.habitos,
    required this.isLoading,
  });

  HomeState copyWith({String? saludo, List<Habito>? habitos, bool? isLoading}) {
    return HomeState(
      saludo: saludo ?? this.saludo,
      habitos: habitos ?? this.habitos,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HomeNotifier extends StateNotifier<AsyncValue<HomeState>> {
  final HomeRepository _repository;

  HomeNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final habitos = await _repository.getHabitos(DateTime.now());
      state = AsyncValue.data(HomeState(
        saludo: '${EcbDateUtils.getSaludo()}, Santiago!',
        habitos: habitos,
        isLoading: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> actualizarProgreso(String id, int valor) async {
    await _repository.actualizarProgreso(id, valor);
    _loadData();
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, AsyncValue<HomeState>>((ref) {
  return HomeNotifier(HomeRepository());
});
