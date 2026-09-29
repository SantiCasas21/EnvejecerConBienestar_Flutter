import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/medicamento_model.dart';

part 'medicamento_repository.g.dart';

class MedicamentoRepository {
  final Dio _dio;

  MedicamentoRepository(this._dio);

  Future<List<Medicamento>> getMedicamentos({int? tratamientoId}) async {
    final response = await _dio.get(
      '/medicamentos',
      queryParameters: tratamientoId != null ? {'tratamiento_id': tratamientoId} : null,
    );
    return (response.data as List)
        .map((json) => Medicamento.fromJson(json))
        .toList();
  }

  Future<Medicamento> getMedicamento(int id) async {
    final response = await _dio.get('/medicamentos/$id');
    return Medicamento.fromJson(response.data);
  }

  Future<Medicamento> createMedicamento(Map<String, dynamic> data) async {
    final response = await _dio.post('/medicamentos', data: data);
    return Medicamento.fromJson(response.data);
  }

  Future<Medicamento> updateMedicamento(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/medicamentos/$id', data: data);
    return Medicamento.fromJson(response.data);
  }

  Future<void> deleteMedicamento(int id) async {
    await _dio.delete('/medicamentos/$id');
  }

  Future<Medicamento> toggleMedicamento(int id) async {
    final response = await _dio.patch('/medicamentos/$id/toggle');
    return Medicamento.fromJson(response.data);
  }

  Future<Medicamento> reabastecerMedicamento(int id, int cantidad) async {
    final response = await _dio.post(
      '/medicamentos/$id/reabastecer',
      data: {'cantidad': cantidad},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('medicamento')) {
      return Medicamento.fromJson(data['medicamento']);
    }
    return Medicamento.fromJson(data);
  }
}

@riverpod
MedicamentoRepository medicamentoRepository(Ref ref) {
  return MedicamentoRepository(ref.watch(apiClientProvider));
}
