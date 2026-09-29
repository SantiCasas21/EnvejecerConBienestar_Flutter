import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
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
  final List<String> _todosEmojis = [
    '🍎', '🥑', '👟', '💧', '🧠', '💊', '😴', '🚲', '🌿', '🌻', '☕', '🧡'
  ];

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
    final emojisSeleccionados = _todosEmojis.take(_totalPares).toList();
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
          // Cálculo amigable de puntaje con bono por pocos intentos
          int puntosBase = _totalPares * 50;
          int factorIntentos = (_intentos <= _totalPares + 2) ? 100 : 50;
          final puntaje = puntosBase + factorIntentos;

          await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
                tipoJuego: 'Buscar Pares',
                puntaje: puntaje,
              );

          if (mounted) {
            VictoriaPuntajeDialog.mostrar(
              context: context,
              nombreJuego: 'Buscar Pares (${_textoDificultad(_dificultad)})',
              puntaje: puntaje,
              mensajePersonalizado:
                  '¡Encontraste todas las parejas en $_intentos intentos! El ejercicio visual asociativo reactiva tu memoria a corto plazo.',
              onJugarDeNuevo: _iniciarJuego,
            );
          }
        }
      } else {
        _bloqueado = true;
        Timer(const Duration(milliseconds: 900), () {
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
        return '3 Pares (Suave)';
      case ParesDificultad.medio6Pares:
        return '6 Pares (Medio)';
      case ParesDificultad.desafio8Pares:
        return '8 Pares (Desafío)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🧠 Buscar Pares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: AppColors.gamesViolet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reiniciar partida',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _iniciarJuego,
          ),
        ],
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
                    _buildChip('Suave (3 Pares)', ParesDificultad.facil3Pares),
                    const SizedBox(width: 8),
                    _buildChip('Medio (6 Pares)', ParesDificultad.medio6Pares),
                    const SizedBox(width: 8),
                    _buildChip('Desafío (8 Pares)', ParesDificultad.desafio8Pares),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Marcadores de Estado ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Chip(
                    avatar: const Text('🎯', style: TextStyle(fontSize: 18)),
                    label: Text('Intentos: $_intentos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    backgroundColor: AppColors.gamesViolet.withValues(alpha: 0.15),
                  ),
                  Chip(
                    avatar: const Text('✅', style: TextStyle(fontSize: 18)),
                    label: Text('Pares: $_paresEncontrados / $_totalPares', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    backgroundColor: AppColors.healthGreen.withValues(alpha: 0.18),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Cuadrícula de Cartas Grandes y Accesibles ──
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _columnasGrid,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _cartas.length,
                  itemBuilder: (context, index) {
                    final carta = _cartas[index];
                    final visible = carta.estaVolteada || carta.estaEmparejada;

                    return GestureDetector(
                      onTap: () => _tocarCarta(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        decoration: BoxDecoration(
                          color: carta.estaEmparejada
                              ? Colors.green.shade100
                              : visible
                                  ? Colors.white
                                  : AppColors.gamesViolet,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: carta.estaEmparejada
                                ? AppColors.healthGreen
                                : visible
                                    ? AppColors.gamesViolet
                                    : AppColors.gamesViolet,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            visible ? carta.emoji : '❓',
                            style: TextStyle(
                              fontSize: _dificultad == ParesDificultad.facil3Pares
                                  ? 52
                                  : _dificultad == ParesDificultad.medio6Pares
                                      ? 40
                                      : 32,
                              color: visible ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
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
      selectedColor: AppColors.gamesViolet,
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
