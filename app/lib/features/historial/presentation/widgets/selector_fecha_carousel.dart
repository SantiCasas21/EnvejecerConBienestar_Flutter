import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/resumen_adherencia_model.dart';

/// Selector horizontal de fechas ergonómico tipo carrusel con botones táctiles ≥ 70dp de altura
class SelectorFechaCarousel extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<CumplimientoDiarioModel> cumplimientos;

  const SelectorFechaCarousel({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.cumplimientos = const [],
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double? _obtenerPorcentajeDia(DateTime dt) {
    final iso = _formatIsoDate(dt);
    for (final c in cumplimientos) {
      if (c.fecha == iso) {
        return c.porcentaje;
      }
    }
    return null;
  }

  String _getDiaSemanaAbrev(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'LUN';
      case DateTime.tuesday:
        return 'MAR';
      case DateTime.wednesday:
        return 'MIÉ';
      case DateTime.thursday:
        return 'JUE';
      case DateTime.friday:
        return 'VIE';
      case DateTime.saturday:
        return 'SÁB';
      case DateTime.sunday:
        return 'DOM';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final dias = List.generate(28, (index) => hoy.subtract(Duration(days: index)));

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final dt = dias[index];
          final isSelected = _isSameDay(dt, selectedDate);
          final isHoy = index == 0;
          final isAyer = index == 1;
          final pct = _obtenerPorcentajeDia(dt);

          Color dotColor;
          if (pct == null) {
            dotColor = Colors.transparent;
          } else if (pct >= 80) {
            dotColor = AppColors.successGreen;
          } else if (pct >= 50) {
            dotColor = AppColors.warningAmber;
          } else {
            dotColor = AppColors.textSecondary.withValues(alpha: 0.5);
          }

          String etiquetaSuperior;
          if (isHoy) {
            etiquetaSuperior = '⭐ Hoy';
          } else if (isAyer) {
            etiquetaSuperior = '⏪ Ayer';
          } else {
            etiquetaSuperior = _getDiaSemanaAbrev(dt.weekday);
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onDateSelected(dt),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 86,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryTeal : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryTeal
                        : AppColors.divider.withValues(alpha: 0.8),
                    width: isSelected ? 2.0 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      etiquetaSuperior,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isHoy ? AppColors.primaryTeal : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dt.day}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
