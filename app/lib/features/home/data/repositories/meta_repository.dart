import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/meta_model.dart';

part 'meta_repository.g.dart';

class MetaRepository {
  final Dio _dio;

  MetaRepository(this._dio);

  Future<List<MetaModel>> getMetas() async {
    final response = await _dio.get('/metas');
    return (response.data as List).map((json) => MetaModel.fromJson(json)).toList();
  }

  Future<MetaModel> createMeta(Map<String, dynamic> data) async {
    final response = await _dio.post('/metas', data: data);
    return MetaModel.fromJson(response.data);
  }

  Future<MetaModel> incrementarProgreso(int id, {int valor = 1}) async {
    final response = await _dio.patch('/metas/$id/progreso', data: {'valor': valor});
    return MetaModel.fromJson(response.data);
  }

  Future<void> deleteMeta(int id) async {
    await _dio.delete('/metas/$id');
  }
}

@riverpod
MetaRepository metaRepository(Ref ref) {
  return MetaRepository(ref.watch(apiClientProvider));
}
