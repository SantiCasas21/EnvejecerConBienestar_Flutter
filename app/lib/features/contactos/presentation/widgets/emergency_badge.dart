import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';

class EmergencyBadge extends StatelessWidget {
  const EmergencyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('🚨 SOS', style: AppTypography.pequeno().copyWith(color: AppColors.textInverse)),
    );
  }
}
