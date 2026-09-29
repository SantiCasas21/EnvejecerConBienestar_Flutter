import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTypography {
  static TextStyle titulo() => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle subtitulo() => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle cuerpo() => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle pequeno() => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );
}
