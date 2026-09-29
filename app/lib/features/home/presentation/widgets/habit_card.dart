import 'package:flutter/material.dart';
import '../../data/models/habito_model.dart';
import '../../../../core/widgets/ecb_card.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../config/theme/app_colors.dart';

class HabitCard extends StatelessWidget {
  final Habito habito;

  const HabitCard({super.key, required this.habito});

  @override
  Widget build(BuildContext context) {
    return EcbCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(habito.tipo, style: AppTypography.subtitulo()),
          const SizedBox(height: 16),
          Text('${habito.progresoActual} / ${habito.meta}', style: AppTypography.titulo()),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: habito.porcentaje,
            backgroundColor: AppColors.backgroundSecondary,
            color: AppColors.primaryOrange,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primaryOrange, size: 48),
            onPressed: () {
              // Update progress
            },
          ),
        ],
      ),
    );
  }
}
