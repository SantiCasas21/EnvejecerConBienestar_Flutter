import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/habito_model.dart';

part 'habito_repository.g.dart';

class HabitoRepository {
  final Dio _dio;

  HabitoRepository(this._dio);

  Future<List<Habito>> getHabitos(String fecha) async {
    final response = await _dio.get('/habitos', queryParameters: {'fecha': fecha});
    return (response.data as List).map((json) => Habito.fromJson(json)).toList();
  }

  Future<Habito> createHabito(Map<String, dynamic> data) async {
    final response = await _dio.post('/habitos', data: data);
    return Habito.fromJson(response.data);
  }

  Future<void> actualizarProgreso(int id, int valor) async {
    await _dio.patch('/habitos/$id/progreso', data: {'valor': valor});
  }
}

@riverpod
HabitoRepository habitoRepository(Ref ref) {
  return HabitoRepository(ref.watch(apiClientProvider));
}
