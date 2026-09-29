import 'package:flutter/material.dart';
import '../../../../core/widgets/ecb_card.dart';
import '../../../../config/theme/app_typography.dart';

class GameStats extends StatelessWidget {
  final int intentos;
  final int tiempo;

  const GameStats({super.key, required this.intentos, required this.tiempo});

  @override
  Widget build(BuildContext context) {
    return EcbCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('Intentos', style: AppTypography.pequeno()),
              Text('$intentos', style: AppTypography.titulo()),
            ],
          ),
          Column(
            children: [
              Text('Tiempo', style: AppTypography.pequeno()),
              Text('${tiempo}s', style: AppTypography.titulo()),
            ],
          ),
        ],
      ),
    );
  }
}
