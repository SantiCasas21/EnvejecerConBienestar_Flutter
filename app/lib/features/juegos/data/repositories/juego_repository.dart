import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/actividad_cognitiva_model.dart';

part 'juego_repository.g.dart';

class JuegoRepository {
  final Dio _dio;

  // Solo almacena partidas jugadas offline en la sesión actual (inicia vacío para no contaminar usuarios nuevos).
  static final List<ActividadCognitiva> _localActividades = [];

  JuegoRepository(this._dio);

  Future<ActividadCognitiva> guardarPuntaje(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/juegos/puntaje', data: data);
      return ActividadCognitiva.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      final nueva = ActividadCognitiva(
        id: DateTime.now().millisecondsSinceEpoch,
        usuarioId: 0,
        tipoJuego: data['tipo_juego'] as String? ?? 'Juego',
        puntaje: (data['puntaje'] as num?)?.toInt() ?? 0,
        nivelDificultad: data['nivel_dificultad'] as String? ?? 'intermedio',
        fechaRealizacion: DateTime.now(),
      );
      _localActividades.insert(0, nueva);
      return nueva;
    }
  }

  Future<List<ActividadCognitiva>> getHistorial({
    int? dias,
    bool familiar = false,
    int limite = 30,
  }) async {
    try {
      final query = <String, dynamic>{
        'limite': limite,
        'familiar': familiar,
      };
      if (dias != null && dias > 0) {
        query['dias'] = dias;
      }
      final response = await _dio.get(
        '/juegos/historial',
        queryParameters: query,
      );
      return (response.data as List)
          .map((json) => ActividadCognitiva.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _localActividades.take(limite).toList();
    }
  }

  Future<List<PuntosPorJuegoModel>> getPuntosPorJuego() async {
    try {
      final response = await _dio.get('/juegos/puntos-por-juego');
      return (response.data as List)
          .map((json) => PuntosPorJuegoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ActividadCognitiva>> getMejoresPuntajes({String? tipoJuego, int limite = 3}) async {
    try {
      final query = <String, dynamic>{'limite': limite};
      if (tipoJuego != null && tipoJuego.isNotEmpty && tipoJuego.toLowerCase() != 'todos') {
        query['tipo_juego'] = tipoJuego;
      }
      final response = await _dio.get(
        '/juegos/mejores',
        queryParameters: query,
      );
      return (response.data as List)
          .map((json) => ActividadCognitiva.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      var filtradas = List<ActividadCognitiva>.from(_localActividades);
      if (tipoJuego != null && tipoJuego.isNotEmpty && tipoJuego.toLowerCase() != 'todos') {
        final query = tipoJuego.toLowerCase().trim();
        filtradas = filtradas.where((a) {
          final tj = a.tipoJuego.toLowerCase();
          return tj.contains(query) || query.contains(tj);
        }).toList();
      }
      filtradas.sort((a, b) => b.puntaje.compareTo(a.puntaje));
      return filtradas.take(limite).toList();
    }
  }

  Future<EstadisticasJuegosModel> getEstadisticas() async {
    try {
      final response = await _dio.get('/juegos/estadisticas');
      return EstadisticasJuegosModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      int totalPuntos = 0;
      int recordMaximo = 0;
      for (var act in _localActividades) {
        totalPuntos += act.puntaje;
        if (act.puntaje > recordMaximo) recordMaximo = act.puntaje;
      }
      return EstadisticasJuegosModel(
        totalPuntos: totalPuntos,
        partidasJugadas: _localActividades.length,
        recordMaximo: recordMaximo,
        juegoFavorito: _localActividades.isNotEmpty ? _localActividades.first.tipoJuego : 'Ninguno',
      );
    }
  }

  Future<PodioFamiliarRespuestaModel> getPodioFamiliar({String? tipoJuego}) async {
    try {
      final query = <String, dynamic>{};
      if (tipoJuego != null && tipoJuego.isNotEmpty && tipoJuego.toLowerCase() != 'todos') {
        query['tipo_juego'] = tipoJuego;
      }
      final response = await _dio.get(
        '/juegos/podio-familiar',
        queryParameters: query,
      );
      return PodioFamiliarRespuestaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return PodioFamiliarRespuestaModel(
        totalMiembros: 0,
        hayVinculacion: false,
        filtroJuego: tipoJuego ?? 'Todos',
        codigoVinculacionUsuario: '',
        podio: const [],
      );
    }
  }
}

@riverpod
JuegoRepository juegoRepository(Ref ref) {
  return JuegoRepository(ref.watch(apiClientProvider));
}
