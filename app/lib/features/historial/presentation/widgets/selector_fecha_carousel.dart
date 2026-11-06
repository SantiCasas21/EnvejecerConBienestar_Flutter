import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/resumen_adherencia_model.dart';

/// Selector semanal ergonómico de 7 días (Lunes a Domingo) con navegación entre semanas y gestos táctiles
class SelectorSemanalWidget extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<CumplimientoDiarioModel> cumplimientos;

  const SelectorSemanalWidget({
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

  String _formatearRangoSemana(DateTime inicio, DateTime fin) {
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    if (inicio.month == fin.month) {
      return '${inicio.day} - ${fin.day} de ${meses[fin.month]} ${fin.year}';
    } else if (inicio.year == fin.year) {
      return '${inicio.day} ${meses[inicio.month]} - ${fin.day} ${meses[fin.month]} ${fin.year}';
    } else {
      return '${inicio.day} ${meses[inicio.month]} ${inicio.year} - ${fin.day} ${meses[fin.month]} ${fin.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime hoy = DateTime.now();
    final DateTime hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);

    // Calcular el Lunes de la semana de la fecha seleccionada
    final DateTime fechaBase = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final DateTime inicioSemana = fechaBase.subtract(Duration(days: fechaBase.weekday - 1));
    final List<DateTime> diasSemana = List.generate(7, (i) => inicioSemana.add(Duration(days: i)));
    final DateTime finSemana = diasSemana.last;

    final bool esSemanaActual = diasSemana.any((d) => _isSameDay(d, hoyNormalizado));

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 250) {
          // Deslizar hacia la derecha -> Semana anterior
          HapticFeedback.selectionClick();
          onDateSelected(selectedDate.subtract(const Duration(days: 7)));
        } else if (velocity < -250) {
          // Deslizar hacia la izquierda -> Semana siguiente
          HapticFeedback.selectionClick();
          onDateSelected(selectedDate.add(const Duration(days: 7)));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Barra de Navegación de la Semana ──
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  color: AppColors.primaryTeal,
                  tooltip: 'Semana anterior',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDateSelected(selectedDate.subtract(const Duration(days: 7)));
                  },
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatearRangoSemana(inicioSemana, finSemana),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (esSemanaActual) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Semana Actual',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  color: AppColors.primaryTeal,
                  tooltip: 'Semana siguiente',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDateSelected(selectedDate.add(const Duration(days: 7)));
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Los 7 Días de la Semana (Lunes a Domingo) ──
            LayoutBuilder(
              builder: (context, constraints) {
                final double anchoTotal = constraints.maxWidth;
                final bool cabeEnRow = anchoTotal >= 340;

                if (cabeEnRow) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: diasSemana.map((dt) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: _buildPildoraDia(dt, hoyNormalizado),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  return SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 7,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 50,
                          child: _buildPildoraDia(diasSemana[index], hoyNormalizado),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPildoraDia(DateTime dt, DateTime hoyNormalizado) {
    final bool isSelected = _isSameDay(dt, selectedDate);
    final bool isHoy = _isSameDay(dt, hoyNormalizado);
    final bool isAyer = _isSameDay(dt, hoyNormalizado.subtract(const Duration(days: 1)));
    final double? pct = _obtenerPorcentajeDia(dt);

    Color dotColor;
    if (isSelected) {
      dotColor = Colors.white;
    } else if (pct == null) {
      dotColor = const Color(0xFFCBD5E1);
    } else if (pct >= 80) {
      dotColor = AppColors.successGreen;
    } else if (pct >= 50) {
      dotColor = AppColors.warningAmber;
    } else {
      dotColor = AppColors.textSecondary.withValues(alpha: 0.4);
    }

    String etiquetaDia;
    if (isHoy) {
      etiquetaDia = '⭐ Hoy';
    } else if (isAyer) {
      etiquetaDia = '⏪ Ayer';
    } else {
      etiquetaDia = _getDiaSemanaAbrev(dt.weekday);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onDateSelected(dt);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 78,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTeal : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryTeal
                  : (isHoy ? AppColors.primaryTeal : AppColors.divider.withValues(alpha: 0.8)),
              width: isSelected || isHoy ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : (isHoy
                    ? [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  etiquetaDia,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: isHoy ? 11 : 12,
                    fontWeight: isHoy || isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isHoy ? AppColors.primaryTeal : AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${dt.day}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias para compatibilidad con llamadas existentes
typedef SelectorFechaCarousel = SelectorSemanalWidget;
