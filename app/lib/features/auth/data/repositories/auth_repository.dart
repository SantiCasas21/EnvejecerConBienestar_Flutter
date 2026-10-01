import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import 'package:envejecer_con_bienestar/core/storage/secure_storage_service.dart';
import '../models/usuario_model.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storageService;

  AuthRepository(this._dio, this._storageService);

  Future<UsuarioModel> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final data = response.data;
    await _storageService.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );

    return UsuarioModel.fromJson(data['usuario']);
  }

  Future<UsuarioModel> register(
    String nombre,
    String email,
    String password, {
    String rol = 'adulto_mayor',
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'rol': rol,
      },
    );

    final data = response.data;
    if (data['access_token'] != null) {
      await _storageService.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
    }

    return UsuarioModel.fromJson(data['usuario']);
  }

  Future<UsuarioModel?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.data != null && response.data['usuario'] != null) {
        return UsuarioModel.fromJson(response.data['usuario']);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    await _storageService.clearTokens();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageServiceProvider),
  );
}
