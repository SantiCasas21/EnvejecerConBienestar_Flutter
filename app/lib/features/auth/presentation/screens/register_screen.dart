import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authNotifierProvider.notifier).register(
            _nombreController.text.trim(),
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
      appBar: AppBar(
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30, color: AppColors.primaryTeal),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryTeal, width: 2.5),
                    ),
                    child: const Center(
                      child: Text(
                        '🌸',
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Únete a nosotros!',
                  textAlign: TextAlign.center,
                  style: AppTypography.titulo().copyWith(
                    color: AppColors.primaryTeal,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea tu perfil para personalizar tus horarios de salud y metas diarias',
                  textAlign: TextAlign.center,
                  style: AppTypography.cuerpo().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 28),

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
                        const Icon(Icons.info_outline, color: AppColors.emergencyRed, size: 26),
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

                // Nombre completo
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  style: AppTypography.cuerpo().copyWith(fontSize: 19),
                  decoration: InputDecoration(
                    labelText: 'Tu Nombre completo',
                    hintText: 'Ej: María Gómez',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryTeal, size: 28),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 18),

                // Correo electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.cuerpo().copyWith(fontSize: 19),
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'maria@ejemplo.com',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryTeal, size: 28),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.cuerpo().copyWith(fontSize: 19),
                  decoration: InputDecoration(
                    labelText: 'Contraseña segura',
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryTeal, size: 28),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTypography.cuerpo().copyWith(fontSize: 19),
                  decoration: InputDecoration(
                    labelText: 'Confirma tu contraseña',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.primaryTeal, size: 28),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                    if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón Registrarme
                SizedBox(
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: authState.status == AuthStatus.loading ? null : _submit,
                    icon: authState.status == AuthStatus.loading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.check_circle_outline, size: 26),
                    label: authState.status == AuthStatus.loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : const Text(
                            'Registrarme y Comenzar',
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
                const SizedBox(height: 20),

                // Volver a login
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    '¿Ya tienes cuenta? Inicia sesión aquí',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
