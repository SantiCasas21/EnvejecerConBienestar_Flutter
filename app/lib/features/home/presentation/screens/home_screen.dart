import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/call_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../contactos/presentation/providers/contactos_provider.dart';
import '../../../medicamentos/presentation/providers/medicamentos_provider.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../providers/metas_provider.dart';
import '../widgets/add_meta_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return '☀️ ¡Buenos días';
    } else if (hora >= 12 && hora < 19) {
      return '🌤️ ¡Buenas tardes';
    } else {
      return '🌙 ¡Buenas noches';
    }
  }

  void _llamarSOS(BuildContext context, WidgetRef ref) async {
    final contactosAsync = ref.read(contactosNotifierProvider);
    final contactos = contactosAsync.value ?? [];
    final perfil = ref.read(perfilNotifierProvider).value;

    String? telefonoSOS = perfil?.contactoEmergenciaTelefono;
    if (telefonoSOS == null || telefonoSOS.isEmpty) {
      final sos = contactos.where((c) => c.esEmergencia).firstOrNull;
      telefonoSOS = sos?.telefono;
    }

    if (telefonoSOS != null && telefonoSOS.isNotEmpty) {
      await CallService.realizarLlamada(telefonoSOS);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ No tienes un contacto de emergencia configurado. Agrégalo en tu Perfil o Contactos.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _abrirAddMeta(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddMetaDialog(),
    );

    if (result != null) {
      ref.read(metasNotifierProvider.notifier).addMeta(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final perfilAsync = ref.watch(perfilNotifierProvider);
    final medicamentosAsync = ref.watch(medicamentosNotifierProvider);
    final metasAsync = ref.watch(metasNotifierProvider);

    final nombreUsuario = authState.user?.nombre ?? 'Amigo/a';
    final perfil = perfilAsync.value;
    final estaCompleto = perfil?.estaCompleto ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryTeal,
          onRefresh: () async {
            ref.invalidate(medicamentosNotifierProvider);
            ref.invalidate(metasNotifierProvider);
            ref.invalidate(perfilNotifierProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Encabezado de Saludo Dinámico ──
                Text(
                  '${_obtenerSaludo()}, $nombreUsuario!',
                  style: AppTypography.titulo().copyWith(
                    fontSize: 26,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuidar de tu bienestar es vivir con alegría y tranquilidad.',
                  style: AppTypography.cuerpo().copyWith(
                    fontSize: 17,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Banner Amigable de Ficha Médica Incompleta (Solo si no está al 100%) ──
                if (!estaCompleto) ...[
                  InkWell(
                    onTap: () => context.push('/perfil/editar'),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryTeal, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryTeal, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tu Ficha Médica está al ${perfil?.porcentajeCompletitudEntero ?? 0}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Toca aquí para completarla y registrar tus contactos de urgencia.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.primaryTeal),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Botón SOS Prominente (72dp de alto, Rojo Carmesí) ──
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton.icon(
                    onPressed: () => _llamarSOS(context, ref),
                    icon: const Icon(Icons.sos_rounded, size: 40, color: Colors.white),
                    label: const Text(
                      'BOTÓN SOS DE EMERGENCIA',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Sección Medicinas de Hoy ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '💊 Medicinas de Hoy',
                      style: AppTypography.subtitulo().copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                medicamentosAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: AppColors.primaryTeal),
                    ),
                  ),
                  error: (err, _) => Text('Error al cargar medicinas: $err', style: AppTypography.cuerpo()),
                  data: (medicamentos) {
                    if (medicamentos.isEmpty) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '🌿 No tienes medicamentos registrados para hoy.',
                            style: AppTypography.cuerpo().copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    final pendientes = medicamentos.where((m) => !(m.estaTomado ?? false)).toList();

                    return Column(
                      children: [
                        if (pendientes.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primaryTeal, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '✨ Próxima dosis pendiente:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(pendientes.first.icono, style: const TextStyle(fontSize: 34)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pendientes.first.nombre,
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${pendientes.first.miligramos ?? ""} - Cada ${pendientes.first.frecuencia ?? 8} horas',
                                            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(medicamentosNotifierProvider.notifier).toggleTomado(pendientes.first.id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.healthGreen,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(90, 48),
                                      ),
                                      child: const Text('Tomar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Card(
                            color: AppColors.completedLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Text('✅', style: TextStyle(fontSize: 28)),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '¡Excelente! Has tomado todas tus medicinas programadas para hoy.',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // ── Sección Mis Logros y Metas ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🎯 Mis Logros y Metas',
                      style: AppTypography.subtitulo().copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primaryTeal, size: 34),
                      onPressed: () => _abrirAddMeta(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                metasAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: AppColors.primaryTeal),
                    ),
                  ),
                  error: (err, _) => Text('Error al cargar metas: $err', style: AppTypography.cuerpo()),
                  data: (metas) {
                    if (metas.isEmpty) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text('🎯 ¡Empieza un hábito hoy!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Agrega metas como tomar agua o caminar para mantenerte activo.', textAlign: TextAlign.center),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () => _abrirAddMeta(context, ref),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(200, 48),
                                ),
                                child: const Text('Agregar Mi Primera Meta'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: metas.map((meta) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(meta.icono, style: const TextStyle(fontSize: 30)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(meta.nombre, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                                          Text('Progreso: ${meta.progreso} / ${meta.objetivo} ${meta.unidad}', style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryTeal, size: 34),
                                      onPressed: () {
                                        ref.read(metasNotifierProvider.notifier).incrementarProgreso(meta.id);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: meta.porcentaje,
                                    minHeight: 12,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      meta.completada ? AppColors.completed : AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  meta.obtenerMensajeMotivacional(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: meta.completada ? AppColors.completed : AppColors.textSecondary,
                                    fontWeight: meta.completada ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
