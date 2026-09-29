import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';

class ToggleTomadoButton extends StatelessWidget {
  final bool tomado;
  final VoidCallback onPressed;
  final String texto;

  const ToggleTomadoButton({
    super.key,
    required this.tomado,
    required this.onPressed,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 48,
        decoration: BoxDecoration(
          color: tomado ? AppColors.healthGreen : AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          style: AppTypography.cuerpo().copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
