import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _mostrarBotonContinuar = false;

  @override
  void initState() {
    super.initState();
    // Temporizador de seguridad: si tras 3 segundos no ha cambiado de pantalla, mostrar botón manual
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mostrarBotonContinuar = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryTeal, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🌿',
                    style: TextStyle(fontSize: 54),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Envejecer con Bienestar',
                textAlign: TextAlign.center,
                style: AppTypography.titulo().copyWith(
                  color: AppColors.primaryTeal,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cuidando tu salud, memoria y autonomía',
                textAlign: TextAlign.center,
                style: AppTypography.cuerpo().copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
              ),
              if (_mostrarBotonContinuar) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).logout();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Ir al Inicio de Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(240, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
