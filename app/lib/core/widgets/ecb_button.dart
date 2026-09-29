import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

enum EcbButtonVariant { primary, emergency, secondary, success }

class EcbButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final EcbButtonVariant variant;

  const EcbButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = EcbButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = AppColors.textInverse;
    double height = 56;

    switch (variant) {
      case EcbButtonVariant.primary:
        bgColor = AppColors.primaryOrange;
        break;
      case EcbButtonVariant.emergency:
        bgColor = AppColors.emergencyRed;
        height = 72;
        break;
      case EcbButtonVariant.secondary:
        bgColor = Colors.transparent;
        textColor = AppColors.primaryOrange;
        break;
      case EcbButtonVariant.success:
        bgColor = AppColors.healthGreen;
        break;
    }

    final button = variant == EcbButtonVariant.secondary
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, height),
              side: const BorderSide(color: AppColors.primaryOrange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(text, style: AppTypography.cuerpo().copyWith(color: textColor, fontWeight: FontWeight.bold)),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              minimumSize: Size(double.infinity, height),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(text, style: AppTypography.cuerpo().copyWith(color: textColor, fontWeight: FontWeight.bold)),
          );

    return button;
  }
}
