import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/actividad_cognitiva_model.dart';
import '../../data/models/juego_ficha_model.dart';
import '../../data/repositories/juegos_repository.dart';
import '../../data/repositories/juego_repository.dart';

// ── PROVIDERS DE SALÓN DE LA FAMA Y ESTADÍSTICAS ──

/// Proveedor para el historial reciente de partidas del usuario
final historialJuegosProvider = FutureProvider<List<ActividadCognitiva>>((ref) async {
  final repo = ref.watch(juegoRepositoryProvider);
  return repo.getHistorial();
});

class HistorialParams {
  final int? dias;
  final bool familiar;
  const HistorialParams({this.dias, this.familiar = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistorialParams &&
          runtimeType == other.runtimeType &&
          dias == other.dias &&
          familiar == other.familiar;

  @override
  int get hashCode => dias.hashCode ^ familiar.hashCode;
}

/// Proveedor de historial filtrable por días y por círculo familiar
final historialFiltradoProvider = FutureProvider.family<List<ActividadCognitiva>, HistorialParams>((ref, params) async {
  final repo = ref.watch(juegoRepositoryProvider);
  return repo.getHistorial(dias: params.dias, familiar: params.familiar);
});

/// Proveedor de los 5 minijuegos ordenados por puntos acumulados
final puntosPorJuegoProvider = FutureProvider<List<PuntosPorJuegoModel>>((ref) async {
  final repo = ref.watch(juegoRepositoryProvider);
  return repo.getPuntosPorJuego();
});

/// Proveedor del Top 3 (o personalizado) con copitas, filtrable por tipo de juego
final mejoresPuntajesProvider = FutureProvider.family<List<ActividadCognitiva>, String?>((ref, tipoJuego) async {
  final repo = ref.watch(juegoRepositoryProvider);
  return repo.getMejoresPuntajes(tipoJuego: tipoJuego, limite: 3);
});

/// Proveedor de estadísticas generales (puntos totales, partidas, récord)
final estadisticasJuegosProvider = FutureProvider<EstadisticasJuegosModel>((ref) async {
  final repo = ref.watch(juegoRepositoryProvider);
  return repo.getEstadisticas();
});

/// Proveedor de podio familiar por tipo de juego (o global si tipoJuego es null)
final podioFamiliarProvider = FutureProvider.family<PodioFamiliarRespuestaModel, String?>((ref, tipoJuego) async {
  final repo = ref.watch(juegoRepositoryProvider);
  return repo.getPodioFamiliar(tipoJuego: tipoJuego);
});

/// Notifier para guardar puntajes y refrescar automáticamente el historial y podio
final guardarPuntajeNotifierProvider = Provider((ref) {
  return GuardarPuntajeManager(ref);
});

class GuardarPuntajeManager {
  final Ref _ref;
  GuardarPuntajeManager(this._ref);

  Future<int?> registrarPuntaje({
    required String tipoJuego,
    required int puntaje,
    String nivelDificultad = 'intermedio',
  }) async {
    try {
      final repo = _ref.read(juegoRepositoryProvider);

      // Consultamos los mejores antes de guardar para ver si este puntaje entra al podio
      final previos = await repo.getMejoresPuntajes(tipoJuego: tipoJuego, limite: 3);
      int? posicionPodio;
      if (previos.isEmpty || puntaje >= previos[0].puntaje) {
        posicionPodio = 1;
      } else if (previos.length < 2 || puntaje >= previos[1].puntaje) {
        posicionPodio = 2;
      } else if (previos.length < 3 || puntaje >= previos[2].puntaje) {
        posicionPodio = 3;
      }

      await repo.guardarPuntaje({
        'tipo_juego': tipoJuego,
        'puntaje': puntaje,
        'nivel_dificultad': nivelDificultad,
      });

      // Invalidamos providers para que el Salón de la Fama y el podio se actualicen de inmediato
      _ref.invalidate(historialJuegosProvider);
      _ref.invalidate(historialFiltradoProvider);
      _ref.invalidate(puntosPorJuegoProvider);
      _ref.invalidate(mejoresPuntajesProvider);
      _ref.invalidate(estadisticasJuegosProvider);
      _ref.invalidate(podioFamiliarProvider);

      return posicionPodio;
    } catch (_) {
      return null;
    }
  }
}

// ── ESTADO LEGACY PARA JUEGO DE FICHAS ──
class JuegosState {
  final List<JuegoFicha> fichas;
  final int intentos;
  final int tiempoTranscurrido;
  final bool juegoTerminado;

  const JuegosState({
    required this.fichas,
    required this.intentos,
    required this.tiempoTranscurrido,
    required this.juegoTerminado,
  });

  JuegosState copyWith({
    List<JuegoFicha>? fichas,
    int? intentos,
    int? tiempoTranscurrido,
    bool? juegoTerminado,
  }) {
    return JuegosState(
      fichas: fichas ?? this.fichas,
      intentos: intentos ?? this.intentos,
      tiempoTranscurrido: tiempoTranscurrido ?? this.tiempoTranscurrido,
      juegoTerminado: juegoTerminado ?? this.juegoTerminado,
    );
  }
}

class JuegosNotifier extends StateNotifier<JuegosState> {
  final JuegosRepository _repository;
  Timer? _timer;
  int? _primeraFichaIndex;
  bool _bloqueado = false;

  JuegosNotifier(this._repository)
      : super(const JuegosState(
          fichas: [],
          intentos: 0,
          tiempoTranscurrido: 0,
          juegoTerminado: false,
        )) {
    iniciarJuego();
  }

  void iniciarJuego() {
    _timer?.cancel();

    final valores = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊'];
    final todosValores = [...valores, ...valores]..shuffle();

    final fichas = List.generate(
      todosValores.length,
      (index) => JuegoFicha(id: index, valor: todosValores[index]),
    );

    state = JuegosState(
      fichas: fichas,
      intentos: 0,
      tiempoTranscurrido: 0,
      juegoTerminado: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.juegoTerminado) {
        timer.cancel();
      } else {
        state = state.copyWith(tiempoTranscurrido: state.tiempoTranscurrido + 1);
      }
    });
  }

  void voltearFicha(int index) async {
    if (_bloqueado ||
        state.fichas[index].estaVolteada ||
        state.fichas[index].estaEmparejada) {
      return;
    }

    final nuevasFichas = List<JuegoFicha>.from(state.fichas);
    nuevasFichas[index] = nuevasFichas[index].copyWith(estaVolteada: true);
    state = state.copyWith(fichas: nuevasFichas);

    if (_primeraFichaIndex == null) {
      _primeraFichaIndex = index;
    } else {
      _bloqueado = true;
      state = state.copyWith(intentos: state.intentos + 1);

      final primeraFicha = nuevasFichas[_primeraFichaIndex!];
      final segundaFicha = nuevasFichas[index];

      if (primeraFicha.valor == segundaFicha.valor) {
        nuevasFichas[_primeraFichaIndex!] =
            primeraFicha.copyWith(estaEmparejada: true);
        nuevasFichas[index] = segundaFicha.copyWith(estaEmparejada: true);
        _primeraFichaIndex = null;
        _bloqueado = false;
        state = state.copyWith(fichas: nuevasFichas);

        if (nuevasFichas.every((f) => f.estaEmparejada)) {
          state = state.copyWith(juegoTerminado: true);
          _repository.savePuntaje(state.intentos, 'Fácil');
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        nuevasFichas[_primeraFichaIndex!] =
            primeraFicha.copyWith(estaVolteada: false);
        nuevasFichas[index] = segundaFicha.copyWith(estaVolteada: false);
        _primeraFichaIndex = null;
        _bloqueado = false;
        state = state.copyWith(fichas: nuevasFichas);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final juegosProvider =
    StateNotifierProvider<JuegosNotifier, JuegosState>((ref) {
  return JuegosNotifier(JuegosRepository());
});
