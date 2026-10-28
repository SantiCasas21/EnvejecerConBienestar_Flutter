import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Tarjeta accesible de resumen de adherencia diaria con psicología positiva sin culpa
class TarjetaAdherenciaDiaria extends StatelessWidget {
  final double porcentaje;
  final int tomadas;
  final int pospuestas;
  final int omitidas;
  final int totalEsperadas;
  final String fechaFormateada;

  const TarjetaAdherenciaDiaria({
    super.key,
    required this.porcentaje,
    required this.tomadas,
    required this.pospuestas,
    required this.omitidas,
    required this.totalEsperadas,
    required this.fechaFormateada,
  });

  @override
  Widget build(BuildContext context) {
    Color colorGauge;
    Color colorFondoGauge;
    String mensajeMotivador;
    IconData iconoEstado;

    if (porcentaje >= 80) {
      colorGauge = AppColors.successGreen;
      colorFondoGauge = const Color(0xFFDCFCE7);
      mensajeMotivador = '¡Excelente constancia! 🌟 Has cumplido tus tomas de este día.';
      iconoEstado = Icons.verified_rounded;
    } else if (porcentaje >= 50) {
      colorGauge = AppColors.warningAmber;
      colorFondoGauge = const Color(0xFFFEF3C7);
      mensajeMotivador = '¡Buen avance! ☀️ Sigues cuidando tu salud con dedicación.';
      iconoEstado = Icons.sentiment_satisfied_alt_rounded;
    } else {
      colorGauge = AppColors.primaryTeal;
      colorFondoGauge = const Color(0xFFE0F2F1);
      mensajeMotivador = '🌱 Día en proceso. ¡Cada toma cuenta para tu bienestar!';
      iconoEstado = Icons.spa_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con fecha
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fechaFormateada,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(iconoEstado, color: colorGauge, size: 24),
            ],
          ),
          const SizedBox(height: 14),

          // Bloque Central: Gauge y Mensaje
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Círculo de porcentaje
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: (porcentaje / 100).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: colorFondoGauge,
                      valueColor: AlwaysStoppedAnimation<Color>(colorGauge),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${porcentaje.round()}%',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colorGauge,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Mensaje motivacional
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mensajeMotivador,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalEsperadas > 0
                          ? '$tomadas de $totalEsperadas dosis registradas'
                          : 'Sin prescripciones registradas este día',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Fila de Badges Resumen (Tomadas, Pospuestas, Omitidas)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                label: '$tomadas Tomadas',
                icon: Icons.check_circle_rounded,
                bgColor: const Color(0xFFDCFCE7),
                textColor: const Color(0xFF166534),
              ),
              _buildBadge(
                label: '$pospuestas Pospuestas',
                icon: Icons.snooze_rounded,
                bgColor: const Color(0xFFFEF3C7),
                textColor: const Color(0xFF92400E),
              ),
              _buildBadge(
                label: '$omitidas Omitidas',
                icon: Icons.remove_circle_outline_rounded,
                bgColor: const Color(0xFFF1F5F9),
                textColor: const Color(0xFF475569),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
