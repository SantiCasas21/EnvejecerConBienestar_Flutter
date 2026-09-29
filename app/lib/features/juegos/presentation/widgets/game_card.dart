import 'package:flutter/material.dart';
import '../../data/models/juego_ficha_model.dart';
import '../../../../config/theme/app_colors.dart';

class GameCard extends StatelessWidget {
  final JuegoFicha ficha;
  final VoidCallback onTap;

  const GameCard({super.key, required this.ficha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: ficha.estaVolteada || ficha.estaEmparejada
            ? Container(
                key: const ValueKey(true),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryOrange, width: 2),
                ),
                child: Center(
                  child: Text(ficha.valor, style: const TextStyle(fontSize: 40)),
                ),
              )
            : Container(
                key: const ValueKey(false),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('?', style: TextStyle(fontSize: 40, color: AppColors.textSecondary)),
                ),
              ),
      ),
    );
  }
}
