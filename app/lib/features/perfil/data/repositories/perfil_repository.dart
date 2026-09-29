import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/perfil_model.dart';

part 'perfil_repository.g.dart';

class PerfilRepository {
  final Dio _dio;

  PerfilRepository(this._dio);

  Future<PerfilModel?> getPerfil() async {
    try {
      final response = await _dio.get('/perfil');
      if (response.data == null) return null;
      if (response.data is Map && response.data.containsKey('perfil') && response.data['perfil'] == null) {
        return null;
      }
      return PerfilModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PerfilModel> guardarPerfil(Map<String, dynamic> data) async {
    final response = await _dio.put('/perfil', data: data);
    return PerfilModel.fromJson(response.data);
  }
}

@riverpod
PerfilRepository perfilRepository(Ref ref) {
  return PerfilRepository(ref.watch(apiClientProvider));
}
