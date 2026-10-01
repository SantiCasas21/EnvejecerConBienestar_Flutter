import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../config/theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/cuidador_dashboard_screen.dart';
import '../../features/medicamentos/presentation/screens/medicamentos_screen.dart';
import '../../features/medicamentos/presentation/screens/medicamento_detail_screen.dart';
import '../../features/juegos/presentation/screens/juegos_screen.dart';
import '../../features/juegos/presentation/screens/buscar_pares_screen.dart';
import '../../features/juegos/presentation/screens/ordenar_secuencia_screen.dart';
import '../../features/juegos/presentation/screens/secuencia_luces_screen.dart';
import '../../features/juegos/presentation/screens/sopa_letras_screen.dart';
import '../../features/juegos/presentation/screens/trivia_screen.dart';
import '../../features/juegos/presentation/screens/sudoku_screen.dart';
import '../../features/contactos/presentation/screens/contactos_screen.dart';
import '../../features/contactos/presentation/screens/contacto_detail_screen.dart';
import '../../features/perfil/presentation/screens/perfil_screen.dart';
import '../../features/perfil/presentation/screens/editar_perfil_screen.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (int index) => navigationShell.goBranch(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.medication_rounded, size: 28), label: 'Medicina'),
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset_rounded, size: 28), label: 'Juegos'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_rounded, size: 28), label: 'Contactos'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'Perfil'),
        ],
      ),
    );
  }
}

@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';
      final isSplash = location == '/splash';

      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return isSplash ? null : '/splash';
      }

      final isAuthenticated = authState.status == AuthStatus.authenticated;

      if (!isAuthenticated) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      if (isLoggingIn || isRegistering || isSplash) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) {
                  final user = authState.user;
                  if (user != null && user.esCuidador) {
                    return const CuidadorDashboardScreen();
                  }
                  return const HomeScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/medicamentos',
                builder: (context, state) => const MedicamentosScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => MedicamentoDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/juegos',
                builder: (context, state) => const JuegosScreen(),
                routes: [
                  GoRoute(
                    path: 'buscar-pares',
                    builder: (context, state) => const BuscarParesScreen(),
                  ),
                  GoRoute(
                    path: 'secuencia-luces',
                    builder: (context, state) => const SecuenciaLucesScreen(),
                  ),
                  GoRoute(
                    path: 'ordenar-secuencia',
                    builder: (context, state) => const SecuenciaLucesScreen(),
                  ),
                  GoRoute(
                    path: 'sopa-letras',
                    builder: (context, state) => const SopaLetrasScreen(),
                  ),
                  GoRoute(
                    path: 'trivia',
                    builder: (context, state) => const TriviaScreen(),
                  ),
                  GoRoute(
                    path: 'sudoku',
                    builder: (context, state) => const SudokuScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contactos',
                builder: (context, state) => const ContactosScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ContactoDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (context, state) => const PerfilScreen(),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (context, state) => const EditarPerfilScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// Compatibilidad estática para pruebas o accesos directos
class AppRouter {
  static GoRouter get router => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/cuidador', builder: (context, state) => const CuidadorDashboardScreen()),
      GoRoute(path: '/medicamentos', builder: (context, state) => const MedicamentosScreen()),
      GoRoute(path: '/juegos', builder: (context, state) => const JuegosScreen()),
      GoRoute(path: '/contactos', builder: (context, state) => const ContactosScreen()),
      GoRoute(path: '/perfil', builder: (context, state) => const PerfilScreen()),
    ],
  );
}
