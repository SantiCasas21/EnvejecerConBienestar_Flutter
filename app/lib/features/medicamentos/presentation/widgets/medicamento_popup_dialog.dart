import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/notification_service.dart';
import '../../data/models/medicamento_model.dart';
import '../../data/models/tratamiento_model.dart';
import '../providers/medicamentos_provider.dart';
import '../providers/tratamientos_provider.dart';

class MedicamentoPopupDialog extends ConsumerWidget {
  final Medicamento medicamento;

  const MedicamentoPopupDialog({
    super.key,
    required this.medicamento,
  });

  static Future<void> mostrar(BuildContext context, Medicamento medicamento) {
    return showDialog<void>(
      context: context,
      builder: (_) => MedicamentoPopupDialog(medicamento: medicamento),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el estado reactivo del medicamento por si cambia
    final medicamentosList = ref.watch(medicamentosNotifierProvider).value ?? [];
    final med = medicamentosList.firstWhere(
      (m) => m.id == medicamento.id,
      orElse: () => medicamento,
    );

    final tratamientosList = ref.watch(tratamientosNotifierProvider).value ?? [];
    TratamientoModel? tratVinculado;
    if (med.tratamientoId != null) {
      tratVinculado = tratamientosList.where((t) => t.id == med.tratamientoId).firstOrNull;
    }

    final tomado = med.estaTomado ?? false;
    final horas = med.horarioDiario;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── CABECERA Y AVATAR DEL MEDICAMENTO ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: tomado ? AppColors.completedLight : AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tomado ? AppColors.completed : AppColors.primaryTeal,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(med.icono, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.nombre,
                          style: AppTypography.titulo().copyWith(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${med.miligramos != null ? "${med.miligramos} mg • " : ""}Cada ${med.frecuencia ?? 8} horas',
                          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        // Badge de estado de la toma
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: tomado ? AppColors.completedLight : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tomado ? AppColors.healthGreen : AppColors.primaryTeal),
                          ),
                          child: Text(
                            tomado ? '✅ Tomado hoy' : '⏳ Dosis pendiente hoy',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: tomado ? AppColors.primaryDark : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 28, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Tratamiento vinculado si existe
              if (tratVinculado != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🩺', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tratamiento: ${tratVinculado.diagnostico}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 24, thickness: 1.5, color: AppColors.border),

              // ── SECCIÓN 1: HORARIO Y ALARMAS PROGRAMADAS ──
              Row(
                children: [
                  const Icon(Icons.alarm_rounded, color: AppColors.primaryTeal, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Alarmas y Horario del Día',
                    style: AppTypography.subtitulo().copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Lista de alarmas del día
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ...horas.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final hora = entry.value;
                      final horaTexto12 = Medicamento.formatearTimeOfDay(hora);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryTeal, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Toma $idx del día',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ),
                            Text(
                              horaTexto12,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    // Botón de prueba sonora
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primaryTeal),
                        label: const Text('Probar Alarma Sonora', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          await NotificationService.probarAlarmaSonora();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🔔 Alarma de prueba para ${med.nombre}'),
                                backgroundColor: AppColors.healthGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── SECCIÓN 2: INVENTARIO DE PASTILLAS Y STOCK ──
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: AppColors.primaryTeal, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Inventario en Botiquín',
                    style: AppTypography.subtitulo().copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: med.alertaInventario ? AppColors.emergencyRed : AppColors.border,
                    width: med.alertaInventario ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: med.colorStock.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication_rounded, color: med.colorStock, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.textoInventario,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: med.alertaInventario ? AppColors.emergencyRed : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Autonomía estimada: ${med.diasAutonomia} días de medicación',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Notas o Indicaciones Especiales
              if (med.notas != null && med.notas!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.shade900, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          med.notas!,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // ── BOTONES DE ACCIÓN PRINCIPALES ──
              // Botón 1: Marcar como tomado
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(medicamentosNotifierProvider.notifier).toggleTomado(med.id);
                  },
                  icon: Icon(
                    tomado ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 22,
                  ),
                  label: Text(
                    tomado ? '✓ Medicamento Tomado Hoy' : 'Marcar como Tomado Ahora',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tomado ? AppColors.completed : AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón 2: Editar / Ajustar horario
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/medicamentos/${med.id}');
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.primaryTeal),
                  label: const Text('Modificar Alarma o Dosis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
