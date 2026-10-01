import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/boton_volver_juegos.dart';
import '../widgets/victoria_puntaje_dialog.dart';

enum ParesDificultad { facil3Pares, medio6Pares, desafio8Pares }

class BuscarParesScreen extends ConsumerStatefulWidget {
  const BuscarParesScreen({super.key});

  @override
  ConsumerState<BuscarParesScreen> createState() => _BuscarParesScreenState();
}

class _CartaItem {
  final int id;
  final String emoji;
  bool estaVolteada = false;
  bool estaEmparejada = false;

  _CartaItem({
    required this.id,
    required this.emoji,
  });
}

class _BuscarParesScreenState extends ConsumerState<BuscarParesScreen> {
  // ── BANCO EXTENDIDO DE MÁS DE 40 ÍCONOS TEMÁTICOS ──
  static const List<String> _superBancoEmojis = [
    // Frutas y Alimentos
    '🍎', '🥑', '🍇', '🍊', '🍉', '🍌', '🍓', '🍒', '🍍', '🥥', '🥝', '🥕',
    // Salud y Vida Activa
    '👟', '💧', '🧠', '💊', '😴', '🚲', '🌿', '🌻', '☕', '🧡', '🩺', '🧘',
    // Naturaleza y Animales
    '🐶', '🐱', '🐰', '🦊', '🐼', '🐬', '🌺', '🌈', '🌳', '🌞', '🕊️', '🦋',
    // Cultura y Arte
    '🎨', '📚', '🎵', '🎸', '🎭', '🎻', '🏛️', '🧩',
  ];

  static const Color _temaColor = Color(0xFF6366F1); // Índigo Calma y Vitalidad

  ParesDificultad _dificultad = ParesDificultad.medio6Pares;
  List<_CartaItem> _cartas = [];
  int _primerIndice = -1;
  bool _bloqueado = false;
  int _intentos = 0;
  int _paresEncontrados = 0;

  int get _totalPares {
    switch (_dificultad) {
      case ParesDificultad.facil3Pares:
        return 3;
      case ParesDificultad.medio6Pares:
        return 6;
      case ParesDificultad.desafio8Pares:
        return 8;
    }
  }

  int get _columnasGrid {
    switch (_dificultad) {
      case ParesDificultad.facil3Pares:
        return 2;
      case ParesDificultad.medio6Pares:
        return 3;
      case ParesDificultad.desafio8Pares:
        return 4;
    }
  }

  @override
  void initState() {
    super.initState();
    _iniciarJuego();
  }

  void _iniciarJuego() {
    final barajados = List<String>.from(_superBancoEmojis)..shuffle();
    final emojisSeleccionados = barajados.take(_totalPares).toList();
    final parEmojis = [...emojisSeleccionados, ...emojisSeleccionados];
    parEmojis.shuffle();

    setState(() {
      _cartas = List.generate(
        parEmojis.length,
        (index) => _CartaItem(id: index, emoji: parEmojis[index]),
      );
      _primerIndice = -1;
      _bloqueado = false;
      _intentos = 0;
      _paresEncontrados = 0;
    });
  }

  void _tocarCarta(int index) async {
    if (_bloqueado || _cartas[index].estaVolteada || _cartas[index].estaEmparejada) return;

    setState(() {
      _cartas[index].estaVolteada = true;
    });

    if (_primerIndice == -1) {
      _primerIndice = index;
    } else {
      _intentos++;
      final primer = _cartas[_primerIndice];
      final segundo = _cartas[index];

      if (primer.emoji == segundo.emoji) {
        setState(() {
          primer.estaEmparejada = true;
          segundo.estaEmparejada = true;
          _paresEncontrados++;
          _primerIndice = -1;
        });

        if (_paresEncontrados == _totalPares) {
          int puntosBase;
          int bonusPrecision = 0;
          if (_dificultad == ParesDificultad.facil3Pares) {
            puntosBase = 90;
            if (_intentos <= 5) bonusPrecision = 30;
          } else if (_dificultad == ParesDificultad.medio6Pares) {
            puntosBase = 200;
            if (_intentos <= 10) bonusPrecision = 50;
          } else {
            puntosBase = 320;
            if (_intentos <= 14) bonusPrecision = 80;
          }
          final puntaje = puntosBase + bonusPrecision;

          final nivelStr = _dificultad == ParesDificultad.facil3Pares
              ? 'basico'
              : _dificultad == ParesDificultad.medio6Pares
                  ? 'intermedio'
                  : 'avanzado';

          final pos = await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
                tipoJuego: 'Buscar Pares',
                puntaje: puntaje,
                nivelDificultad: nivelStr,
              );

          if (mounted) {
            VictoriaPuntajeDialog.mostrar(
              context: context,
              nombreJuego: 'Buscar Pares (${_textoDificultad(_dificultad)})',
              puntaje: puntaje,
              posicionTop: pos,
              mensajePersonalizado:
                  '¡Encontraste todas las parejas en $_intentos intentos! El ejercicio visual asociativo reactiva tu memoria a corto plazo.',
              onJugarDeNuevo: _iniciarJuego,
            );
          }
        }
      } else {
        _bloqueado = true;
        Timer(const Duration(milliseconds: 850), () {
          if (mounted) {
            setState(() {
              primer.estaVolteada = false;
              segundo.estaVolteada = false;
              _primerIndice = -1;
              _bloqueado = false;
            });
          }
        });
      }
    }
  }

  String _textoDificultad(ParesDificultad d) {
    switch (d) {
      case ParesDificultad.facil3Pares:
        return '3 Pares (Básico)';
      case ParesDificultad.medio6Pares:
        return '6 Pares (Intermedio)';
      case ParesDificultad.desafio8Pares:
        return '8 Pares (Avanzado)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 190,
        leading: const BotonVolverJuegos(),
        title: const Text('🧠 Buscar Pares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: _temaColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // ── Selector de Dificultad ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChip('Básico (3 Pares)', ParesDificultad.facil3Pares),
                    const SizedBox(width: 8),
                    _buildChip('Intermedio (6 Pares)', ParesDificultad.medio6Pares),
                    const SizedBox(width: 8),
                    _buildChip('Avanzado (8 Pares)', ParesDificultad.desafio8Pares),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Marcadores de Estado y Botón de Reinicio Físico ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Text('🎯', style: TextStyle(fontSize: 16)),
                    label: Text('Intentos: $_intentos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    backgroundColor: _temaColor.withValues(alpha: 0.12),
                  ),
                  Chip(
                    avatar: const Text('✅', style: TextStyle(fontSize: 16)),
                    label: Text('Pares: $_paresEncontrados / $_totalPares', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    backgroundColor: AppColors.healthGreen.withValues(alpha: 0.16),
                  ),
                  ElevatedButton.icon(
                    onPressed: _iniciarJuego,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reiniciar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _temaColor,
                      side: const BorderSide(color: _temaColor, width: 1.5),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Cuadrícula Responsiva con LayoutBuilder ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double ancho = constraints.maxWidth;
                    final double alto = constraints.maxHeight;
                    final int cols = _columnasGrid;
                    final int filas = (_cartas.length / cols).ceil();

                    const double espaciado = 10.0;
                    final double anchoCelda = (ancho - ((cols - 1) * espaciado)) / cols;
                    final double altoCelda = (alto - ((filas - 1) * espaciado)) / filas;
                    final double ratio = (anchoCelda / altoCelda).clamp(0.75, 1.25);

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: espaciado,
                        mainAxisSpacing: espaciado,
                        childAspectRatio: ratio,
                      ),
                      itemCount: _cartas.length,
                      itemBuilder: (context, index) {
                        final carta = _cartas[index];
                        final visible = carta.estaVolteada || carta.estaEmparejada;

                        return GestureDetector(
                          onTap: () => _tocarCarta(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: carta.estaEmparejada
                                  ? const Color(0xFFD1FAE5) // Menta suave
                                  : visible
                                      ? Colors.white
                                      : _temaColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: carta.estaEmparejada
                                    ? AppColors.healthGreen
                                    : _temaColor,
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                visible ? carta.emoji : '❓',
                                style: TextStyle(
                                  fontSize: _dificultad == ParesDificultad.facil3Pares
                                      ? 46
                                      : _dificultad == ParesDificultad.medio6Pares
                                          ? 36
                                          : 30,
                                  color: visible ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, ParesDificultad dif) {
    final selected = _dificultad == dif;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedColor: _temaColor,
      backgroundColor: Colors.white,
      onSelected: (val) {
        if (val) {
          setState(() => _dificultad = dif);
          _iniciarJuego();
        }
      },
    );
  }
}
