import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/notification_service.dart';
import '../../data/models/medicamento_model.dart';

class DosisProgramada {
  final Medicamento medicamento;
  final TimeOfDay hora;

  DosisProgramada({required this.medicamento, required this.hora});

  int get minutosDelDia => hora.hour * 60 + hora.minute;

  String get horaFormateada {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get franja {
    if (hora.hour >= 6 && hora.hour < 12) return '🌅 Mañana';
    if (hora.hour >= 12 && hora.hour < 18) return '☀️ Tarde';
    return '🌙 Noche';
  }
}

class RecordatoriosTimeline extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final Function(Medicamento med) onToggleTomado;

  const RecordatoriosTimeline({
    super.key,
    required this.medicamentos,
    required this.onToggleTomado,
  });

  List<DosisProgramada> _obtenerDosisOrdenadas() {
    final List<DosisProgramada> lista = [];
    for (final med in medicamentos) {
      for (final h in med.horarioDiario) {
        lista.add(DosisProgramada(medicamento: med, hora: h));
      }
    }
    lista.sort((a, b) => a.minutosDelDia.compareTo(b.minutosDelDia));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    if (medicamentos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏰', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 16),
              Text(
                'Sin recordatorios programados',
                style: AppTypography.subtitulo().copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Agrega medicamentos para generar tu cronograma de alarmas del día.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final todasLasDosis = _obtenerDosisOrdenadas();
    final tomasPendientes = todasLasDosis.where((d) => !(d.medicamento.estaTomado ?? false)).length;
    final tomasCompletadas = todasLasDosis.length - tomasPendientes;

    // Agrupar por franja horaria
    final Map<String, List<DosisProgramada>> agrupadas = {
      '🌅 Mañana': [],
      '☀️ Tarde': [],
      '🌙 Noche': [],
    };

    for (final dosis in todasLasDosis) {
      agrupadas[dosis.franja]?.add(dosis);
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ── Banner Resumen del Día ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recordatorios y Alarmas del Día',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$tomasCompletadas de ${todasLasDosis.length} tomas realizadas hoy',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Probar alarma sonora',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        await NotificationService.probarAlarmaSonora();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('🔔 Alarma activada de prueba'),
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
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Desglose por Franjas Horarias ──
        for (final entry in agrupadas.entries) ...[
          if (entry.value.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: AppTypography.subtitulo().copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.value.length} tomas',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((dosis) {
              final med = dosis.medicamento;
              final estaTomado = med.estaTomado ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: estaTomado ? Colors.grey.shade300 : AppColors.primaryTeal.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                color: estaTomado ? Colors.grey.shade50 : AppColors.cardBackground,
                elevation: estaTomado ? 0.5 : 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Hora en grande
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: estaTomado
                              ? Colors.grey.shade200
                              : AppColors.primaryLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          dosis.horaFormateada,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: estaTomado ? AppColors.textSecondary : AppColors.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Medicamento y miligramos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${med.icono} ${med.nombre}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: estaTomado ? AppColors.textSecondary : AppColors.textPrimary,
                                decoration: estaTomado ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (med.miligramos != null && med.miligramos!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${med.miligramos} mg • Cada ${med.frecuencia ?? 24}h',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Botón de acción rápida
                      ElevatedButton(
                        onPressed: () => onToggleTomado(med),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estaTomado ? Colors.grey.shade300 : AppColors.healthGreen,
                          foregroundColor: estaTomado ? AppColors.textSecondary : Colors.white,
                          elevation: estaTomado ? 0 : 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: Text(
                          estaTomado ? '✓ Tomado' : 'Tomar',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}
