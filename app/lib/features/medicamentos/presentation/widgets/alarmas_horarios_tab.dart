import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/notification_service.dart';
import '../../data/models/medicamento_model.dart';

class AlarmasHorariosTab extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final bool esCuidador;

  const AlarmasHorariosTab({
    super.key,
    required this.medicamentos,
    this.esCuidador = false,
  });

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primaryTeal;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFF0D9488);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Desglosar y ordenar cronológicamente las tomas de hoy
    final List<_TomaCronogramaItem> tomas = [];
    for (final med in medicamentos) {
      for (final hora in med.horarioDiario) {
        tomas.add(
          _TomaCronogramaItem(
            medicamento: med,
            hora: hora,
            minutosDesdeMedianoche: hora.hour * 60 + hora.minute,
          ),
        );
      }
    }
    tomas.sort((a, b) => a.minutosDesdeMedianoche.compareTo(b.minutosDesdeMedianoche));

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner de Confianza ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('⏰', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alarmas Sincronizadas y Activas',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Tus recordatorios están programados para avisarte puntualmente por sonido y vibración.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Botones de Acción (Probar y Sincronizar) ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      NotificationService.probarAlarmaSonora();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Text('🔔', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '¡Prueba emitida! Se ha enviado el recordatorio sonoro de prueba.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.primaryTeal,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_rounded, size: 20),
                    label: const Text(
                      'Probar Alarma',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      NotificationService.reprogramarTodasLasAlarmas(medicamentos);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Text('🔄', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Se sincronizaron y programaron las alarmas de ${medicamentos.length} medicamentos.',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.primaryTeal,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.primaryTeal),
                    label: const Text(
                      'Sincronizar',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Título del Cronograma ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Cronograma de Tomas de Hoy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '${tomas.length} tomas',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Lista Cronológica ──
          if (tomas.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text('💊', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay tomas registradas',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cuando agregues medicamentos a tu plan, aquí aparecerá el horario de cada toma del día ordenado por hora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...tomas.map((item) {
              final med = item.medicamento;
              final diff = item.minutosDesdeMedianoche - nowMinutes;
              final bool yaTomada = med.estaTomado ?? false;

              final String badgeTexto;
              final Color badgeColor;
              final Color badgeBg;

              if (yaTomada) {
                badgeTexto = 'Tomada ✓';
                badgeColor = AppColors.healthGreen;
                badgeBg = Colors.green.shade50;
              } else if (diff >= 0 && diff <= 60) {
                badgeTexto = diff == 0 ? '¡Es ahora!' : 'Próxima en $diff min';
                badgeColor = const Color(0xFFF59E0B);
                badgeBg = Colors.amber.shade50;
              } else if (diff < 0) {
                badgeTexto = 'Hora pasada';
                badgeColor = Colors.grey.shade700;
                badgeBg = Colors.grey.shade100;
              } else {
                badgeTexto = 'Pendiente';
                badgeColor = AppColors.contactsBlue;
                badgeBg = Colors.blue.shade50;
              }

              final medColor = _parseColor(med.colorIcono);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      // Bloque Hora y Estado
                      Container(
                        width: 104,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Medicamento.formatearTimeOfDay(item.hora),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                badgeTexto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Detalle del Medicamento
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(med.icono, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    med.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            if (med.miligramos != null && med.miligramos!.isNotEmpty) ...[
                              Text(
                                '${med.miligramos} mg',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (med.notas != null && med.notas!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                med.notas!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Botón Simular Alarma
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: medColor.withValues(alpha: 0.12),
                          foregroundColor: medColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.notifications_active_outlined, size: 18),
                        label: const Text(
                          'Simular',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () {
                          NotificationService.mostrarAlarmaActiva(
                            context,
                            med,
                            horaToma: item.hora,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _TomaCronogramaItem {
  final Medicamento medicamento;
  final TimeOfDay hora;
  final int minutosDesdeMedianoche;

  _TomaCronogramaItem({
    required this.medicamento,
    required this.hora,
    required this.minutosDesdeMedianoche,
  });
}
