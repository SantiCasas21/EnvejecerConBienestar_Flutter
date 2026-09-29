import 'package:dio/dio.dart';
import 'package:envejecer_con_bienestar/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;
  final Dio dio;

  AuthInterceptor(this.storageService, this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.contains('/auth/login') || options.path.contains('/auth/register')) {
      return super.onRequest(options, handler);
    }

    final token = await storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return super.onRequest(options, handler);
  }
}

class ErrorInterceptor extends Interceptor {
  final SecureStorageService storageService;
  final Dio dio;

  ErrorInterceptor(this.storageService, this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/refresh')) {
      final refreshToken = await storageService.getRefreshToken();
      
      if (refreshToken != null) {
        try {
          final response = await dio.post(
            '/auth/refresh',
            options: Options(
              headers: {'Authorization': 'Bearer $refreshToken'},
            ),
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['access_token'];
            await storageService.saveTokens(
              accessToken: newAccessToken,
              refreshToken: refreshToken,
            );

            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final opts = Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            );
            
            final retryResponse = await dio.request(
              err.requestOptions.path,
              options: opts,
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
            );
            
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          await storageService.clearTokens();
        }
      } else {
        await storageService.clearTokens();
      }
    }
    
    return super.onError(err, handler);
  }
}
