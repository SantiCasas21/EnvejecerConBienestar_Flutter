import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../data/models/tratamiento_model.dart';

class TratamientoCard extends StatelessWidget {
  final TratamientoModel tratamiento;
  final VoidCallback onToggleEstado;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TratamientoCard({
    super.key,
    required this.tratamiento,
    required this.onToggleEstado,
    required this.onDelete,
    this.onEdit,
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
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: esCompletado ? Colors.grey.shade300 : cardColor.withValues(alpha: 0.4),
          width: 1.8,
        ),
      ),
      elevation: esCompletado ? 1 : 3,
      color: esCompletado ? const Color(0xFFF8FAFC) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila Superior: Diagnóstico y Especialidad ──
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
                    style: const TextStyle(fontSize: 26),
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
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: esCompletado ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: esCompletado ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Especialidad médica destacada
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tratamiento.especialidadMedica ?? 'Medicina General',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Médico e Institución ──
            if ((tratamiento.medicoTratante != null && tratamiento.medicoTratante!.isNotEmpty) ||
                (tratamiento.institucionSalud != null && tratamiento.institucionSalud!.isNotEmpty)) ...[
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (tratamiento.medicoTratante != null && tratamiento.medicoTratante!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 18, color: AppColors.primaryTeal),
                        const SizedBox(width: 4),
                        Text(
                          tratamiento.medicoTratante!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (tratamiento.institucionSalud != null && tratamiento.institucionSalud!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          tratamiento.institucionSalud!,
                          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Distinción Clara: Crónico vs Temporal (Barra 12dp) ──
            if (esCronico) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.all_inclusive_rounded, size: 22, color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Terapia Permanente / Tratamiento Crónico',
                        style: TextStyle(
                          fontSize: 15,
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
                      Text(
                        tratamiento.textoProgreso,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${tratamiento.progresoDias?.toStringAsFixed(0) ?? 0}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cardColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ((tratamiento.progresoDias ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 12, // Barra de avance accesible de 12dp
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                    ),
                  ),
                ],
              ),
            ],

            // ── Objetivo Terapéutico (si existe) ──
            if (tratamiento.objetivoTerapeutico != null && tratamiento.objetivoTerapeutico!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Azul claro
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.track_changes, size: 18, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Objetivo: ${tratamiento.objetivoTerapeutico!}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Recomendaciones no farmacológicas (si existen) ──
            if (tratamiento.recomendaciones != null && tratamiento.recomendaciones!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Ámbar suave
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.eco_outlined, size: 18, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tratamiento.recomendaciones!,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Próximo Control Médico ──
            if (tratamiento.proximaCita != null && tratamiento.proximaCita!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.event, size: 18, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 6),
                  Text(
                    'Próxima cita de control: ${tratamiento.proximaCita!}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ],
              ),
            ],

            // ── Medicamentos Vinculados (Chips ergonómicos de 48dp) ──
            if (tratamiento.medicamentos.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Medicamentos vinculados al tratamiento:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tratamiento.medicamentos.map((m) {
                  return Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m.icono, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          '${m.nombre} ${m.miligramos != null ? "${m.miligramos}mg" : ""}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (m.estaTomado ?? false) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Botones de Acción Táctiles Directos (Mínimo 52dp de altura) ──
            Row(
              children: [
                // 1. Botón Estado (Completar / Reanudar)
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: esCompletado ? AppColors.primaryTeal : const Color(0xFF15803D),
                        side: BorderSide(
                          color: esCompletado ? AppColors.primaryTeal : const Color(0xFF15803D),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(
                        esCompletado ? Icons.replay_rounded : Icons.check_circle_outline,
                        size: 22,
                      ),
                      label: Text(
                        esCompletado ? 'Reanudar' : 'Completar',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: onToggleEstado,
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  // 2. Botón Modificar
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D4ED8),
                          side: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_note, size: 22),
                        label: const Text(
                          'Modificar',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // 3. Botón Eliminar
                SizedBox(
                  height: 52,
                  width: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emergencyRed,
                      side: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onDelete,
                    child: const Icon(Icons.delete_outline, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
