import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/widgets/ecb_card.dart';
import '../../data/models/medicamento_model.dart';
import '../providers/medicamentos_provider.dart';
import 'medicamento_popup_dialog.dart';

class MedicamentoCard extends ConsumerWidget {
  final Medicamento medicamento;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const MedicamentoCard({
    super.key,
    required this.medicamento,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tomado = medicamento.estaTomado ?? false;
    final stockBajo = medicamento.alertaInventario;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: EcbCard(
        onTap: onTap ?? () => MedicamentoPopupDialog.mostrar(context, medicamento),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila Principal: Icono, Nombre y Dosis ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tomado ? Colors.grey.shade200 : AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tomado ? AppColors.completed : AppColors.primaryTeal,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(medicamento.icono, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicamento.nombre,
                        style: AppTypography.subtitulo().copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          decoration: tomado ? TextDecoration.lineThrough : null,
                          color: tomado ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${medicamento.miligramos != null ? "${medicamento.miligramos} mg • " : ""}Cada ${medicamento.frecuencia ?? 8} horas',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Botón de ayuda para ver detalle
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: AppColors.primaryTeal, size: 26),
                  tooltip: 'Ver detalle y alarmas',
                  onPressed: () => MedicamentoPopupDialog.mostrar(context, medicamento),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── BANDA DE ALARMA Y HORARIO DE TOMAS ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tomado ? Colors.grey.shade100 : AppColors.primaryLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tomado ? Colors.grey.shade300 : AppColors.primaryTeal.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm_on_rounded,
                    size: 22,
                    color: tomado ? AppColors.textSecondary : AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Alarma: ${medicamento.horaAlarma12}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tomado ? AppColors.textSecondary : AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${medicamento.tomasPorDia} ${medicamento.tomasPorDia == 1 ? "toma" : "tomas"}/día)',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          medicamento.resumenHoras12,
                          style: TextStyle(
                            fontSize: 13,
                            color: tomado ? AppColors.textSecondary : AppColors.primaryDark.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await NotificationService.probarAlarmaSonora();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🔔 Probando alarma sonora para ${medicamento.nombre}'),
                            backgroundColor: AppColors.healthGreen,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Tooltip(
                        message: 'Probar sonido',
                        child: Icon(Icons.volume_up_rounded, size: 22, color: tomado ? AppColors.textSecondary : AppColors.primaryTeal),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Alerta si el inventario está bajo
            if (stockBajo) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Pocas pastillas! Quedan solo ${medicamento.cantidadRestante} en botiquín',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Botón Táctil de Marcado de Toma
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (onToggle != null) {
                    onToggle!();
                  } else {
                    ref.read(medicamentosNotifierProvider.notifier).toggleTomado(medicamento.id);
                  }
                },
                icon: Icon(
                  tomado ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 22,
                ),
                label: Text(
                  medicamento.textoBoton,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tomado ? Colors.grey.shade300 : AppColors.primaryTeal,
                  foregroundColor: tomado ? AppColors.textSecondary : Colors.white,
                  elevation: tomado ? 0 : 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
