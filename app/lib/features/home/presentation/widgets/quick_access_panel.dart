import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/ecb_card.dart';
import '../../../../config/theme/app_typography.dart';

class QuickAccessPanel extends StatelessWidget {
  const QuickAccessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EcbCard(
            onTap: () => context.go('/medicamentos'),
            child: Column(
              children: [
                const Icon(Icons.medication, size: 48, color: Colors.blue),
                const SizedBox(height: 8),
                Text('Medicina', style: AppTypography.subtitulo()),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EcbCard(
            onTap: () => context.go('/contactos'),
            child: Column(
              children: [
                const Icon(Icons.contacts, size: 48, color: Colors.purple),
                const SizedBox(height: 8),
                Text('Contactos', style: AppTypography.subtitulo()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
