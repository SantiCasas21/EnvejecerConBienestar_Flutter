import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/models/resumen_adherencia_model.dart';

/// Sección de bienestar diario con metas de hábitos saludables
class SeccionHabitosDia extends StatelessWidget {
  final List<HabitoHistorialModel> habitos;

  const SeccionHabitosDia({
    super.key,
    required this.habitos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 22, color: AppColors.successGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Metas y Hábitos de este Día',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (habitos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se encontraron hábitos registrados para esta fecha.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...habitos.map((h) => _buildHabitoItem(h)),
        ],
      ),
    );
  }

  Widget _buildHabitoItem(HabitoHistorialModel habito) {
    String icono;
    String titulo;
    String unidad;
    Color colorBarra;

    final tipoLower = habito.tipo.toLowerCase();
    if (tipoLower.contains('agua') || tipoLower.contains('hidratacion')) {
      icono = '💧';
      titulo = 'Hidratación';
      unidad = 'vasos';
      colorBarra = const Color(0xFF0284C7);
    } else if (tipoLower.contains('camin') || tipoLower.contains('paso') || tipoLower.contains('ejercicio')) {
      icono = '🚶';
      titulo = 'Caminata y Movimiento';
      unidad = 'minutos';
      colorBarra = AppColors.successGreen;
    } else if (tipoLower.contains('juego') || tipoLower.contains('mental') || tipoLower.contains('cogniti')) {
      icono = '🧠';
      titulo = 'Gimnasio Mental';
      unidad = 'ejercicios';
      colorBarra = AppColors.secondaryIndigo;
    } else {
      icono = '🎯';
      titulo = habito.tipo;
      unidad = 'unidades';
      colorBarra = AppColors.primaryTeal;
    }

    final double factor = (habito.porcentaje / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${habito.progresoActual} / ${habito.meta} $unidad (${habito.porcentaje.round()}%)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 10,
              backgroundColor: AppColors.divider.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(colorBarra),
            ),
          ),
        ],
      ),
    );
  }
}
