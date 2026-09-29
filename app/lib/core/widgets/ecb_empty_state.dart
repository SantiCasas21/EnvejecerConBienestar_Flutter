import 'package:flutter/material.dart';
import '../../config/theme/app_typography.dart';

class EcbEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const EcbEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.subtitulo()),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.pequeno(), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
