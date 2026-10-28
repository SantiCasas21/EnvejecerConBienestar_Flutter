import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/historial_toma_model.dart';

/// Tarjeta cronológica de toma de medicamento en el historial
class TarjetaTomaHistorial extends StatelessWidget {
  final HistorialTomaModel toma;

  const TarjetaTomaHistorial({
    super.key,
    required this.toma,
  });

  Color _parseColor(String? colorHex, Color defaultColor) {
    if (colorHex == null || colorHex.isEmpty) return defaultColor;
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final medColor = _parseColor(toma.medicamentoColor, AppColors.primaryTeal);

    Color estadoBgColor;
    Color estadoTextColor;
    String estadoTexto;
    IconData estadoIcono;

    if (toma.fueTomada) {
      estadoBgColor = const Color(0xFFDCFCE7);
      estadoTextColor = const Color(0xFF15803D);
      estadoTexto = 'Tomada';
      estadoIcono = Icons.check_circle_rounded;
    } else if (toma.fuePospuesta) {
      estadoBgColor = const Color(0xFFFEF3C7);
      estadoTextColor = const Color(0xFFB45309);
      estadoTexto = 'Pospuesta (+10 min)';
      estadoIcono = Icons.snooze_rounded;
    } else {
      estadoBgColor = const Color(0xFFF1F5F9);
      estadoTextColor = const Color(0xFF475569);
      estadoTexto = 'Omitida';
      estadoIcono = Icons.remove_circle_outline_rounded;
    }

    // Formateo amigable de la hora real si existe
    String detalleHora;
    if (toma.horaReal != null && toma.horaReal!.isNotEmpty) {
      try {
        final dt = DateTime.parse(toma.horaReal!).toLocal();
        final hora = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final min = dt.minute.toString().padLeft(2, '0');
        detalleHora = 'Prog: ${toma.horaProgramada}  •  Real: $hora:$min $ampm';
      } catch (_) {
        detalleHora = 'Prog: ${toma.horaProgramada}';
      }
    } else {
      detalleHora = 'Horario programado: ${toma.horaProgramada}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Ícono, Nombre/Dosis y Badge de Estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cuadro con ícono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: medColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  toma.medicamentoIcono.isNotEmpty ? toma.medicamentoIcono : '💊',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),

              // Nombre y Miligramos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toma.medicamentoNombre ?? 'Medicamento',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      toma.medicamentoMiligramos != null && toma.medicamentoMiligramos!.isNotEmpty
                          ? toma.medicamentoMiligramos!
                          : 'Dosis recetada',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Badge de estado
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: estadoBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcono, size: 15, color: estadoTextColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          estadoTexto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: estadoTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Fila de Horario
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detalleHora,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Nota médica o del paciente (si existe)
          if (toma.notas != null && toma.notas!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.primaryTeal, width: 3.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 16, color: AppColors.primaryTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      toma.notas!,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
