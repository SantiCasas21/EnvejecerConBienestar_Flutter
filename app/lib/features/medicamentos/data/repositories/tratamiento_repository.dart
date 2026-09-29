import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../models/tratamiento_model.dart';

part 'tratamiento_repository.g.dart';

class TratamientoRepository {
  final Dio _dio;

  TratamientoRepository(this._dio);

  Future<List<TratamientoModel>> getTratamientos({String? estado}) async {
    final response = await _dio.get(
      '/tratamientos',
      queryParameters: estado != null ? {'estado': estado} : null,
    );
    return (response.data as List)
        .map((json) => TratamientoModel.fromJson(json))
        .toList();
  }

  Future<TratamientoModel> getTratamiento(int id) async {
    final response = await _dio.get('/tratamientos/$id');
    return TratamientoModel.fromJson(response.data);
  }

  Future<TratamientoModel> createTratamiento(Map<String, dynamic> data) async {
    final response = await _dio.post('/tratamientos', data: data);
    return TratamientoModel.fromJson(response.data);
  }

  Future<TratamientoModel> updateTratamiento(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/tratamientos/$id', data: data);
    return TratamientoModel.fromJson(response.data);
  }

  Future<TratamientoModel> cambiarEstado(int id, String estado) async {
    final response = await _dio.patch('/tratamientos/$id/estado', data: {'estado': estado});
    return TratamientoModel.fromJson(response.data);
  }

  Future<void> deleteTratamiento(int id) async {
    await _dio.delete('/tratamientos/$id');
  }
}

@riverpod
TratamientoRepository tratamientoRepository(Ref ref) {
  return TratamientoRepository(ref.watch(apiClientProvider));
}
