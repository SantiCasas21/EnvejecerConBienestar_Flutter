import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'prueba@envejecer.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authNotifierProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (success && mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono Hero circular de Bienestar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryTeal, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🌿',
                          style: TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título principal de la app
                  Text(
                    'Envejecer con Bienestar',
                    textAlign: TextAlign.center,
                    style: AppTypography.titulo().copyWith(
                      color: AppColors.primaryTeal,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtítulo cálido y claro
                  Text(
                    'Inicia sesión para cuidar de tu salud y vitalidad',
                    textAlign: TextAlign.center,
                    style: AppTypography.cuerpo().copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mensaje de Error destacado (si existe)
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.pendingBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.emergencyRed, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.emergencyRed, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.emergencyRed,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Campo Correo Electrónico
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.cuerpo().copyWith(fontSize: 19),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryTeal, size: 28),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa tu correo electrónico';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Ingresa un correo válido (ej: usuario@correo.com)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTypography.cuerpo().copyWith(fontSize: 19),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryTeal, size: 28),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 26,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      if (v.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón Principal Iniciar Sesión (64dp de alto)
                  SizedBox(
                    height: 64,
                    child: ElevatedButton.icon(
                      onPressed: authState.status == AuthStatus.loading ? null : _submit,
                      icon: authState.status == AuthStatus.loading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.login_rounded, size: 26),
                      label: authState.status == AuthStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.textInverse,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón para ir a Registro
                  OutlinedButton(
                    onPressed: () => context.push('/register'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: AppColors.primaryTeal, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.cardBackground,
                    ),
                    child: const Text(
                      '¿No tienes cuenta? Regístrate aquí',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón Acceso Rápido para Prueba / Demostración
                  TextButton.icon(
                    onPressed: () {
                      ref.read(authNotifierProvider.notifier).entrarModoPrueba();
                    },
                    icon: const Icon(Icons.rocket_launch_rounded, color: AppColors.gamesViolet, size: 22),
                    label: const Text(
                      'Explorar en Modo Prueba (Sin conexión)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gamesViolet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
