import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../models/minijuego_definicion.dart';

class MinijuegosRegistry {
  MinijuegosRegistry._();

  static const MinijuegoDefinicion sudoku = MinijuegoDefinicion(
    id: 'sudoku',
    titulo: 'Sudoku',
    subtitulo: 'Lógica y Razonamiento Numérico',
    descripcion: 'Completa las casillas sin repetir números en filas, columnas ni bloques con pistas deductivas.',
    icono: '🔢',
    ruta: '/juegos/sudoku',
    colorTema: AppColors.primaryTeal,
    habilidadCognitiva: 'Razonamiento y Lógica',
    iconoHabilidad: '💡',
    puntosPorNivel: {
      NivelDificultad.basico: 120,
      NivelDificultad.intermedio: 280,
      NivelDificultad.avanzado: 500,
    },
  );

  static const MinijuegoDefinicion buscarPares = MinijuegoDefinicion(
    id: 'buscar_pares',
    titulo: 'Buscar Pares',
    subtitulo: 'Memoria Visual y Retención',
    descripcion: 'Encuentra las parejas de cartas entre más de 40 ilustraciones temáticas en cuadrícula responsiva.',
    icono: '🧠',
    ruta: '/juegos/buscar-pares',
    colorTema: Color(0xFF6366F1), // Índigo Calma y Vitalidad (reemplaza morado)
    habilidadCognitiva: 'Memoria de Trabajo',
    iconoHabilidad: '⚡',
    puntosPorNivel: {
      NivelDificultad.basico: 120,
      NivelDificultad.intermedio: 250,
      NivelDificultad.avanzado: 400,
    },
  );

  static const MinijuegoDefinicion sopaLetras = MinijuegoDefinicion(
    id: 'sopa_letras',
    titulo: 'Sopa de Letras',
    subtitulo: 'Atención Selectiva y Lenguaje',
    descripcion: 'Desliza tu dedo en trazo continuo para descubrir palabras de salud, cultura y naturaleza.',
    icono: '🔤',
    ruta: '/juegos/sopa-letras',
    colorTema: AppColors.healthGreen,
    habilidadCognitiva: 'Atención y Lenguaje',
    iconoHabilidad: '🔍',
    puntosPorNivel: {
      NivelDificultad.basico: 120,
      NivelDificultad.intermedio: 250,
      NivelDificultad.avanzado: 450,
    },
  );

  static const MinijuegoDefinicion trivia = MinijuegoDefinicion(
    id: 'trivia',
    titulo: 'Trivia de Cultura General',
    subtitulo: 'Sabiduría en 5 Grandes Categorías',
    descripcion: 'Desafía tu mente con preguntas sobre Deportes, Arte, Geografía, Salud y Ciencia con pistas deductivas.',
    icono: '🌍',
    ruta: '/juegos/trivia',
    colorTema: AppColors.contactsBlue,
    habilidadCognitiva: 'Memoria Semántica',
    iconoHabilidad: '📚',
    puntosPorNivel: {
      NivelDificultad.basico: 150,
      NivelDificultad.intermedio: 250,
      NivelDificultad.avanzado: 300,
    },
  );

  static const MinijuegoDefinicion secuenciaLuces = MinijuegoDefinicion(
    id: 'secuencia_luces',
    titulo: 'Secuencia de Luces',
    subtitulo: 'Memoria Inmediata y Reflejos',
    descripcion: 'Memoriza y reproduce la secuencia de luces y cuadrantes luminosos a medida que avanza cada ronda.',
    icono: '💡',
    ruta: '/juegos/secuencia-luces',
    colorTema: AppColors.primaryOrange,
    habilidadCognitiva: 'Memoria de Trabajo y Reflejos',
    iconoHabilidad: '🎯',
    puntosPorNivel: {
      NivelDificultad.basico: 100,
      NivelDificultad.intermedio: 250,
      NivelDificultad.avanzado: 450,
    },
  );

  static const List<MinijuegoDefinicion> todos = [
    sudoku,
    buscarPares,
    sopaLetras,
    trivia,
    secuenciaLuces,
  ];

  static MinijuegoDefinicion? obtenerPorId(String id) {
    try {
      return todos.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  static MinijuegoDefinicion? obtenerPorRuta(String ruta) {
    try {
      return todos.firstWhere((j) => j.ruta == ruta);
    } catch (_) {
      return null;
    }
  }
}
