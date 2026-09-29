import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../data/models/tratamiento_model.dart';

class TratamientoCard extends StatelessWidget {
  final TratamientoModel tratamiento;
  final VoidCallback onToggleEstado;
  final VoidCallback onDelete;

  const TratamientoCard({
    super.key,
    required this.tratamiento,
    required this.onToggleEstado,
    required this.onDelete,
  });

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return AppColors.primaryTeal;
    try {
      final clean = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _parseColor(tratamiento.color);
    final esCronico = tratamiento.esCronico ?? false;
    final esCompletado = tratamiento.esCompletado;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: esCompletado ? Colors.grey.shade300 : cardColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      elevation: esCompletado ? 1 : 2.5,
      color: esCompletado ? Colors.grey.shade50 : AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila Superior: Diagnóstico y Estado ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    esCronico ? '🩺' : '📋',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tratamiento.diagnostico,
                        style: AppTypography.subtitulo().copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: esCompletado ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: esCompletado ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (tratamiento.medicoTratante != null && tratamiento.medicoTratante!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.primaryTeal),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tratamiento.medicoTratante!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'toggle') onToggleEstado();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            esCompletado ? Icons.replay_rounded : Icons.check_circle_outline,
                            color: AppColors.primaryTeal,
                          ),
                          const SizedBox(width: 10),
                          Text(esCompletado ? 'Reanudar tratamiento' : 'Marcar completado'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: AppColors.emergencyRed),
                          const SizedBox(width: 10),
                          const Text('Eliminar tratamiento', style: TextStyle(color: AppColors.emergencyRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Barra de Progreso o Chip de Crónico ──
            if (esCronico) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.all_inclusive_rounded, size: 18, color: AppColors.primaryTeal),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Tratamiento Crónico / Continuo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tratamiento.textoProgreso,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tratamiento.progresoDias?.toStringAsFixed(0) ?? 0}%',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cardColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ((tratamiento.progresoDias ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                    ),
                  ),
                ],
              ),
            ],

            // ── Institución o Centro Médico ──
            if (tratamiento.institucionSalud != null && tratamiento.institucionSalud!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tratamiento.institucionSalud!,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],

            // ── Medicamentos Asociados ──
            if (tratamiento.medicamentos.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Medicamentos vinculados a este tratamiento:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tratamiento.medicamentos.map((m) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m.icono, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          '${m.nombre} ${m.miligramos != null ? "${m.miligramos}mg" : ""}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── Instrucciones o Notas ──
            if (tratamiento.instrucciones != null && tratamiento.instrucciones!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tratamiento.instrucciones!,
                        style: TextStyle(fontSize: 14, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
