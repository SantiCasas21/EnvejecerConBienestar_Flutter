import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/resumen_adherencia_model.dart';

/// Widget con Gauge / Donut circular accesible para visualizar la adherencia global
class AdherenciaDonutWidget extends StatelessWidget {
  final ResumenAdherenciaModel resumen;
  final String periodoTexto;

  const AdherenciaDonutWidget({
    super.key,
    required this.resumen,
    required this.periodoTexto,
  });

  Color _obtenerColor(double pct) {
    if (pct >= 80.0) return AppColors.successGreen;
    if (pct >= 50.0) return const Color(0xFFD97706);
    return const Color(0xFF94A3B8);
  }

  String _obtenerMensaje(double pct) {
    if (pct >= 90.0) return '¡Excelente constancia!';
    if (pct >= 80.0) return '¡Gran cuidado de tu salud!';
    if (pct >= 50.0) return '¡Buen avance diario!';
    return '¡Cada día cuenta!';
  }

  @override
  Widget build(BuildContext context) {
    final pct = resumen.porcentajeAdherenciaGlobal.clamp(0.0, 100.0);
    final color = _obtenerColor(pct);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Donut Circular
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _DonutProgressPainter(
                    porcentaje: pct / 100.0,
                    color: color,
                    backgroundColor: const Color(0xFFF1F5F9),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'Adherencia',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Información contextual a la derecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    periodoTexto,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _obtenerMensaje(pct),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${resumen.totalTomadas} de ${resumen.totalEsperadas} tomas cumplidas con éxito.',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
                if (resumen.racha != null && resumen.racha!.rachaActual > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${resumen.racha!.rachaActual} días de racha activa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutProgressPainter extends CustomPainter {
  final double porcentaje;
  final Color color;
  final Color backgroundColor;

  _DonutProgressPainter({
    required this.porcentaje,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Fondo completo
    canvas.drawCircle(center, radius, bgPaint);

    // Arco de progreso
    if (porcentaje > 0.0) {
      final sweepAngle = 2 * math.pi * porcentaje;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutProgressPainter oldDelegate) {
    return oldDelegate.porcentaje != porcentaje ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
