import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BotonVolverJuegos extends StatelessWidget {
  final Color? colorTexto;
  final Color? colorFondo;

  const BotonVolverJuegos({
    super.key,
    this.colorTexto,
    this.colorFondo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 6.0, bottom: 6.0),
      child: ElevatedButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/juegos');
          }
        },
        icon: Icon(
          Icons.arrow_back_rounded,
          size: 22,
          color: colorTexto ?? Colors.white,
        ),
        label: Text(
          'Volver a Juegos',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorTexto ?? Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorFondo ?? Colors.white.withValues(alpha: 0.22),
          foregroundColor: colorTexto ?? Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(160, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: (colorTexto ?? Colors.white).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
