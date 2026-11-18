import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<UsuarioModel?> loginWithGoogle({String rol = 'adulto_mayor'}) async {
    UserCredential? userCredential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    }

    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('No se pudo obtener el token de autenticación de Google.');
    }

    final response = await _dio.post(
      '/auth/google',
      data: {
        'id_token': idToken,
        'rol': rol,
      },
    );

    final data = response.data;
    await _storageService.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );

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
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
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
