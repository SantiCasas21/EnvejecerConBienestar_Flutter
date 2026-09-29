import 'package:dio/dio.dart';
import 'package:envejecer_con_bienestar/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/secure_storage_service.dart';
import 'api_interceptors.dart';

part 'api_client.g.dart';

@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  final secureStorage = ref.watch(secureStorageServiceProvider);

  dio.interceptors.add(AuthInterceptor(secureStorage, dio));
  dio.interceptors.add(ErrorInterceptor(secureStorage, dio));

  return dio;
}
