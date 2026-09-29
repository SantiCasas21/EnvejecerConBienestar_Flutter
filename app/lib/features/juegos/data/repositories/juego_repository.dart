import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/actividad_cognitiva_model.dart';

part 'juego_repository.g.dart';

class JuegoRepository {
  final Dio _dio;

  JuegoRepository(this._dio);

  Future<ActividadCognitiva> guardarPuntaje(Map<String, dynamic> data) async {
    final response = await _dio.post('/juegos/puntaje', data: data);
    return ActividadCognitiva.fromJson(response.data);
  }

  Future<List<ActividadCognitiva>> getHistorial({int limite = 20}) async {
    try {
      final response = await _dio.get(
        '/juegos/historial',
        queryParameters: {'limite': limite},
      );
      return (response.data as List)
          .map((json) => ActividadCognitiva.fromJson(json))
          .toList();
    } catch (_) {
      return [];
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
          .map((json) => ActividadCognitiva.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<EstadisticasJuegosModel> getEstadisticas() async {
    try {
      final response = await _dio.get('/juegos/estadisticas');
      return EstadisticasJuegosModel.fromJson(response.data);
    } catch (_) {
      return EstadisticasJuegosModel.vacio();
    }
  }
}

@riverpod
JuegoRepository juegoRepository(Ref ref) {
  return JuegoRepository(ref.watch(apiClientProvider));
}
