import 'package:flutter/material.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/widgets/ecb_button.dart';

class VictoryDialog extends StatelessWidget {
  final int intentos;
  final int tiempo;
  final VoidCallback onReiniciar;

  const VictoryDialog({
    super.key,
    required this.intentos,
    required this.tiempo,
    required this.onReiniciar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('¡Victoria!', style: AppTypography.titulo()),
      content: Text('Completaste el juego en $intentos intentos y $tiempo segundos.', style: AppTypography.cuerpo()),
      actions: [
        EcbButton(
          text: 'Jugar de nuevo',
          onPressed: () {
            Navigator.of(context).pop();
            onReiniciar();
          },
        ),
      ],
    );
  }
}
