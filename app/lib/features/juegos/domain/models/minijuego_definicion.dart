import 'package:flutter/material.dart';

enum NivelDificultad { basico, intermedio, avanzado }

extension NivelDificultadExtension on NivelDificultad {
  String get etiqueta {
    switch (this) {
      case NivelDificultad.basico:
        return 'Básico';
      case NivelDificultad.intermedio:
        return 'Intermedio';
      case NivelDificultad.avanzado:
        return 'Avanzado';
    }
  }

  String get id {
    switch (this) {
      case NivelDificultad.basico:
        return 'basico';
      case NivelDificultad.intermedio:
        return 'intermedio';
      case NivelDificultad.avanzado:
        return 'avanzado';
    }
  }
}

class MinijuegoDefinicion {
  final String id;
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final String icono; // Emoji
  final String ruta;
  final Color colorTema;
  final String habilidadCognitiva;
  final String iconoHabilidad;
  final Map<NivelDificultad, int> puntosPorNivel;

  const MinijuegoDefinicion({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.icono,
    required this.ruta,
    required this.colorTema,
    required this.habilidadCognitiva,
    this.iconoHabilidad = '🧠',
    required this.puntosPorNivel,
  });

  int puntosParaNivel(NivelDificultad nivel) {
    return puntosPorNivel[nivel] ?? 100;
  }
}
