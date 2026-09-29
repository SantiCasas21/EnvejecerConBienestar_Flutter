import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/juego_ficha_model.dart';
import 'game_card.dart';
import '../providers/juegos_provider.dart';

class GameBoard extends ConsumerWidget {
  final List<JuegoFicha> fichas;

  const GameBoard({super.key, required this.fichas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: fichas.length,
      itemBuilder: (context, index) {
        return GameCard(
          ficha: fichas[index],
          onTap: () => ref.read(juegosProvider.notifier).voltearFicha(index),
        );
      },
    );
  }
}
