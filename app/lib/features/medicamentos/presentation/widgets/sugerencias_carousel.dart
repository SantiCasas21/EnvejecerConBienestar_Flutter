import 'package:flutter/material.dart';
import '../../data/models/medicamento_model.dart';
import '../../../../core/widgets/ecb_card.dart';
import '../../../../config/theme/app_typography.dart';

/// Carrusel horizontal de sugerencias de medicamentos.
class SugerenciasCarousel extends StatelessWidget {
  final List<Medicamento> sugerencias;
  final Function(Medicamento)? onAgregar;

  const SugerenciasCarousel({super.key, required this.sugerencias, this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('💡 Sugerencias', style: AppTypography.subtitulo()),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sugerencias.length,
            itemBuilder: (context, index) {
              final sug = sugerencias[index];
              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 12.0),
                child: EcbCard(
                  onTap: onAgregar != null ? () => onAgregar!(sug) : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sug.icono, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(sug.nombre, style: AppTypography.cuerpo(), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(
                        '${sug.miligramos} mg',
                        style: AppTypography.pequeno(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
