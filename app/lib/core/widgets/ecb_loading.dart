import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class EcbLoading extends StatelessWidget {
  const EcbLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
      ),
    );
  }
}
