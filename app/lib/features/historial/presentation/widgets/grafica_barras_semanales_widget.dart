import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/resumen_adherencia_model.dart';

/// Widget de Gráfica de Barras adaptada para personas mayores (Senior Data Viz)
/// Muestra los días de la semana con barras anchas, porcentaje explícito en la cabecera
/// y colores cálidos no punitivos (Verde >=80%, Ámbar 50-79%, Gris <50%).
class GraficaBarrasSemanalesWidget extends StatelessWidget {
  final List<CumplimientoDiarioModel> dias;

  const GraficaBarrasSemanalesWidget({
    super.key,
    required this.dias,
  });

  Color _obtenerColorBarra(double porcentaje) {
    if (porcentaje >= 80.0) {
      return AppColors.successGreen;
    } else if (porcentaje >= 50.0) {
      return const Color(0xFFD97706);
    } else {
      return const Color(0xFF94A3B8);
    }
  }

  String _abreviarDia(String diaSemana, String fecha) {
    if (diaSemana.isNotEmpty) {
      final d = diaSemana.toLowerCase();
      if (d.startsWith('lu')) return 'Lun';
      if (d.startsWith('ma')) return 'Mar';
      if (d.startsWith('mi')) return 'Mié';
      if (d.startsWith('ju')) return 'Jue';
      if (d.startsWith('vi')) return 'Vie';
      if (d.startsWith('sá') || d.startsWith('sa')) return 'Sáb';
      if (d.startsWith('do')) return 'Dom';
    }
    try {
      final dt = DateTime.parse(fecha);
      const abrevs = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return abrevs[dt.weekday - 1];
    } catch (_) {
      return 'Día';
    }
  }

  String _extraerDiaNumero(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return dt.day.toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si hay más de 7 días, tomar los últimos 7 para mantener legibilidad visual
    final diasAMostrar = dias.length > 7 ? dias.sublist(dias.length - 7) : dias;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.bar_chart_rounded, color: AppColors.primaryTeal, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cumplimiento por Día',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Últimos 7 días de tu rutina',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Contenedor de las 7 barras
          SizedBox(
            height: 205,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: diasAMostrar.map((dia) {
                final pct = dia.porcentaje.clamp(0.0, 100.0);
                final color = _obtenerColorBarra(pct);
                final abrev = _abreviarDia(dia.diaSemana, dia.fecha);
                final diaNum = _extraerDiaNumero(dia.fecha);

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Texto explícito con el porcentaje arriba de la barra blindado
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${pct.toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Barra vertical accesible
                      Container(
                        width: 26,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: 26,
                          height: (pct / 100.0) * 96,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: pct > 0
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Etiqueta del día
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          abrev,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (diaNum.isNotEmpty)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            diaNum,
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Leyenda explicativa sutil
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLeyendaItem(AppColors.successGreen, '≥ 80% Óptimo'),
              _buildLeyendaItem(const Color(0xFFD97706), '50-79% Aceptable'),
              _buildLeyendaItem(const Color(0xFF94A3B8), '< 50% Por mejorar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaItem(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
