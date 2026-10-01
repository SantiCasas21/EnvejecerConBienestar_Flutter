import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UsuarioModel? user;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UsuarioModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Iniciar verificación en background sin bloquear
    Future.microtask(() => _checkAuthStatus());
    return AuthState(status: AuthStatus.loading);
  }

  Future<void> _checkAuthStatus() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final token = await storage.getAccessToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      if (token == null || token.isEmpty) {
        state = AuthState(status: AuthStatus.unauthenticated, user: null);
        return;
      }

      final user = await ref.read(authRepositoryProvider).getMe().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        await storage.clearTokens();
        state = AuthState(status: AuthStatus.unauthenticated, user: null);
      }
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated, user: null);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user, errorMessage: null);
      return true;
    } on DioException catch (e) {
      // Si es el usuario de prueba y no hay conexión al backend (ej: APK en celular sin backend), permitir acceso de prueba
      if (email.trim().toLowerCase() == 'prueba@envejecer.com' &&
          password == 'password123' &&
          (e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.connectionError ||
           e.type == DioExceptionType.receiveTimeout)) {
        entrarModoPrueba();
        return true;
      }

      String mensaje = 'No se pudo iniciar sesión.';
      if (e.response?.statusCode == 401) {
        mensaje = 'Correo electrónico o contraseña incorrectos.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.receiveTimeout) {
        mensaje = 'No se pudo conectar con el servidor en la nube. Por favor verifica tu conexión a internet.';
      } else if (e.response?.data is Map && e.response?.data['msg'] != null) {
        mensaje = e.response?.data['msg'];
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: mensaje,
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Ocurrió un error inesperado al iniciar sesión.',
      );
      return false;
    }
  }

  Future<bool> register(
    String nombre,
    String email,
    String password, {
    String rol = 'adulto_mayor',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(nombre, email, password, rol: rol);
      state = AuthState(status: AuthStatus.authenticated, user: user, errorMessage: null);
      return true;
    } on DioException catch (e) {
      String mensaje = 'Error al registrar usuario.';
      if (e.response?.statusCode == 409) {
        mensaje = 'Ya existe una cuenta registrada con este correo electrónico.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.receiveTimeout) {
        mensaje = 'No se pudo conectar con el servidor en la nube. Por favor verifica tu conexión a internet.';
      } else if (e.response?.data is Map && e.response?.data['msg'] != null) {
        mensaje = e.response?.data['msg'];
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: mensaje,
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Ocurrió un error inesperado al registrarte.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = AuthState(status: AuthStatus.unauthenticated, user: null);
  }

  void entrarModoPrueba() {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: const UsuarioModel(
        id: 999,
        nombre: 'Adulto Mayor (Prueba)',
        email: 'prueba@envejecer.com',
      ),
    );
  }
}
