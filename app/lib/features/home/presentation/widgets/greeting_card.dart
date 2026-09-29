import 'package:flutter/material.dart';
import '../../../../core/widgets/ecb_card.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';

class GreetingCard extends StatelessWidget {
  final String saludo;

  const GreetingCard({super.key, required this.saludo});

  @override
  Widget build(BuildContext context) {
    return EcbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(saludo, style: AppTypography.titulo()),
          const SizedBox(height: 8),
          Text(EcbDateUtils.formatFecha(DateTime.now()), style: AppTypography.pequeno()),
        ],
      ),
    );
  }
}
