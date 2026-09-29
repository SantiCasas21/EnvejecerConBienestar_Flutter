import 'package:flutter/material.dart';
import '../../data/models/habito_model.dart';
import 'habit_card.dart';

class HabitsCarousel extends StatelessWidget {
  final List<Habito> habitos;

  const HabitsCarousel({super.key, required this.habitos});

  @override
  Widget build(BuildContext context) {
    if (habitos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: habitos.length,
        itemBuilder: (context, index) {
          return HabitCard(habito: habitos[index]);
        },
      ),
    );
  }
}
