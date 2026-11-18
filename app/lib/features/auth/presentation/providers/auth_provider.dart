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
    final storage = ref.read(secureStorageServiceProvider);
    final repo = ref.read(authRepositoryProvider);

    try {
      final token = await storage.getAccessToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      final refreshToken = await storage.getRefreshToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      if ((token == null || token.isEmpty) && (refreshToken == null || refreshToken.isEmpty)) {
        state = AuthState(status: AuthStatus.unauthenticated, user: null);
        return;
      }

      // Arranque instantáneo (0ms): restaurar usuario cacheado sin esperar el cold start de la nube
      final cachedUser = await repo.getCachedUser();
      if (cachedUser != null) {
        state = AuthState(status: AuthStatus.authenticated, user: cachedUser);
      }

      // Sincronizar con el servidor en segundo plano (timeout generoso de 15s)
      try {
        final user = await repo.getMe().timeout(const Duration(seconds: 15));
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } else if (cachedUser == null) {
          state = AuthState(status: AuthStatus.unauthenticated, user: null);
        }
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        // Solo cerramos sesión si el servidor rechazó explícitamente la credencial (401/422 tras intentar refresh)
        if (code == 401 || code == 422) {
          await storage.clearTokens();
          state = AuthState(status: AuthStatus.unauthenticated, user: null);
        } else if (cachedUser == null) {
          state = AuthState(status: AuthStatus.unauthenticated, user: null);
        }
      } catch (_) {
        // En timeout o caída temporal de red, conservamos la sesión cacheada si existe
        if (cachedUser == null) {
          state = AuthState(status: AuthStatus.unauthenticated, user: null);
        }
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

  Future<bool> loginWithGoogle({String rol = 'adulto_mayor'}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .loginWithGoogle(rol: rol);
      if (user == null) {
        state = AuthState(status: AuthStatus.unauthenticated);
        return false;
      }
      state = AuthState(status: AuthStatus.authenticated, user: user, errorMessage: null);
      return true;
    } on DioException catch (e) {
      String mensaje = 'No se pudo completar el acceso con Google.';
      if (e.response?.data is Map && e.response?.data['msg'] != null) {
        mensaje = e.response?.data['msg'];
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: mensaje,
      );
      return false;
    } catch (e) {
      final msgStr = e.toString().toLowerCase();
      final cancelado = msgStr.contains('cancel') || msgStr.contains('popup-closed');
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: cancelado
            ? null
            : 'No se pudo iniciar sesión con Google. Intenta nuevamente.',
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
        id: 3,
        nombre: 'Adulto Mayor Demo',
        email: 'prueba@envejecer.com',
        codigoVinculacion: 'ECB-1002',
      ),
    );
  }
}
