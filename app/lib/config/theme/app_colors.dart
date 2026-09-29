import 'package:flutter/material.dart';

/// Paleta Oficial de Colores "Calma y Vitalidad"
/// Diseñada con un contraste mínimo de 4.5:1 (WCAG AA/AAA) para adultos mayores.
abstract class AppColors {
  // 1. Colores Principales de Marca e Identidad
  /// Teal / Verde Azulado (#0D9488) - Salud, confianza y calma. Botones primarios, barras y encabezados.
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryOrange = Color(0xFF0D9488); // Alias de compatibilidad hacia el primario
  
  /// Fondo claro (#CCFBF1) para resaltar tarjetas activas o selecciones.
  static const Color primaryLight = Color(0xFFCCFBF1);
  
  /// Teal Oscuro (#0F766E) - Estados presionados/activos del color primario.
  static const Color primaryDark = Color(0xFF0F766E);

  /// Lavanda Suave / Índigo (#818CF8) - Paz y descanso. Juegos Cognitivos.
  static const Color secondaryLavender = Color(0xFF818CF8);
  static const Color gamesViolet = Color(0xFF818CF8); // Alias de compatibilidad
  
  /// Fondo claro (#E0E7FF) para contenedores de juegos y actividades lúdicas.
  static const Color secondaryLight = Color(0xFFE0E7FF);

  // 2. Estados de la Aplicación y Alertas Críticas
  /// Rojo Carmesí (#E11D48) - Botón SOS de Emergencia principal y alertas de inventario crítico.
  static const Color emergencyRed = Color(0xFFE11D48);
  
  /// Rojo Carmesí Oscuro (#BE123C) - Sombra y estado presionado del botón SOS.
  static const Color emergencyRedDark = Color(0xFFBE123C);

  /// Verde Esmeralda (#22C55E) - Medicamento tomado con éxito, metas cumplidas.
  static const Color completed = Color(0xFF22C55E);
  static const Color healthGreen = Color(0xFF22C55E); // Alias de éxito/salud
  
  /// Fondo claro (#DCFCE7) de badges y tarjetas de metas completadas.
  static const Color completedLight = Color(0xFFDCFCE7);
  static const Color healthGreenLight = Color(0xFFDCFCE7);

  /// Fondo suave (#FEF2F2) para medicamentos pendientes o no tomados.
  static const Color pendingBackground = Color(0xFFFEF2F2);
  
  /// Borde (#FECACA) de alerta para elementos pendientes.
  static const Color pendingBorder = Color(0xFFFECACA);

  // 3. Fondos, Superficies y Tipografía (Antirreflejo y Alto Contraste)
  /// Fondo general (#F8FAFC, Slate 50) de todas las pantallas. Antirreflejo.
  static const Color background = Color(0xFFF8FAFC);
  
  /// Superficie de tarjetas (#FFFFFF, Frame/Card) para separar contenido del fondo.
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// Fondo secundario (#F1F5F9, Slate 100) para campos de texto e inputs.
  static const Color backgroundSecondary = Color(0xFFF1F5F9);

  /// Texto principal (#1E293B, Slate 800) - Máximo contraste sobre fondos claros.
  static const Color textPrimary = Color(0xFF1E293B);
  
  /// Texto secundario (#64748B, Slate 500) - Subtítulos, horarios y textos de apoyo.
  static const Color textSecondary = Color(0xFF64748B);
  
  /// Texto sobre fondos oscuros o de color (#FFFFFF).
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Líneas divisorias y bordes de tarjetas (#E2E8F0).
  static const Color border = Color(0xFFE2E8F0);
  
  /// Sombra suave para dar relieve tridimensional táctil a los botones.
  static const Color shadow = Color(0x20000000);

  /// Azul para contactos (#0284C7).
  static const Color contactsBlue = Color(0xFF0284C7);

  // Paleta de 10 colores para generación dinámica de avatares según hash del nombre (.NET MAUI Contacto.cs)
  static const List<Color> avatarColors = [
    Color(0xFF0D9488), // Teal
    Color(0xFF818CF8), // Lavanda
    Color(0xFFF97316), // Naranja suave
    Color(0xFF1D4ED8), // Azul rey
    Color(0xFFE11D48), // Carmesí
    Color(0xFF059669), // Esmeralda oscuro
    Color(0xFFD97706), // Ámbar
    Color(0xFF4F46E5), // Índigo
    Color(0xFFBE185D), // Rosa oscuro
    Color(0xFF0284C7), // Celeste
  ];

  /// Genera un color consistente para el avatar a partir del nombre del usuario
  static Color generarColorPorNombre(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) {
      return primaryTeal;
    }
    final hash = nombre.trim().hashCode.abs();
    return avatarColors[hash % avatarColors.length];
  }
}
