import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/boton_volver_juegos.dart';
import '../widgets/victoria_puntaje_dialog.dart';

enum SopaDificultad { basico6x6, intermedio8x8, avanzado10x10 }

class SopaLetrasScreen extends ConsumerStatefulWidget {
  const SopaLetrasScreen({super.key});

  @override
  ConsumerState<SopaLetrasScreen> createState() => _SopaLetrasScreenState();
}

class _SopaLetrasScreenState extends ConsumerState<SopaLetrasScreen> {
  SopaDificultad _dificultad = SopaDificultad.intermedio8x8;

  int _tamano = 8;
  late List<List<String>> _grid;
  late Map<String, List<List<int>>> _palabrasInfo;
  late Map<String, Color> _palabrasColores;

  final Set<String> _palabrasEncontradas = {};
  List<int>? _inicioSeleccion; // [row, col]
  List<int>? _finSeleccion; // [row, col]
  final GlobalKey _gridKey = GlobalKey();

  // ── DEFINICIÓN DE NIVELES Y VOCABULARIO ──

  static const List<List<String>> _grid6x6 = [
    ['S', 'O', 'L', 'A', 'B', 'C'],
    ['P', 'A', 'Z', 'D', 'E', 'F'],
    ['V', 'I', 'D', 'A', 'G', 'H'],
    ['I', 'J', 'K', 'L', 'M', 'N'],
    ['O', 'P', 'Q', 'R', 'S', 'T'],
    ['U', 'V', 'W', 'X', 'Y', 'Z'],
  ];
  static const Map<String, List<List<int>>> _info6x6 = {
    'SOL': [[0, 0], [0, 1], [0, 2]],
    'PAZ': [[1, 0], [1, 1], [1, 2]],
    'VIDA': [[2, 0], [2, 1], [2, 2], [2, 3]],
  };
  static const Map<String, Color> _colores6x6 = {
    'SOL': Color(0xFFF59E0B),
    'PAZ': Color(0xFF0284C7),
    'VIDA': Color(0xFF10B981),
  };

  static const List<List<String>> _grid8x8 = [
    ['A', 'G', 'U', 'A', 'X', 'Y', 'Z', 'W'],
    ['B', 'S', 'A', 'L', 'U', 'D', 'K', 'L'],
    ['C', 'V', 'I', 'D', 'A', 'M', 'N', 'O'],
    ['D', 'E', 'F', 'G', 'H', 'P', 'Q', 'R'],
    ['E', 'P', 'A', 'S', 'O', 'S', 'T', 'U'],
    ['F', 'G', 'H', 'I', 'J', 'A', 'M', 'O'],
    ['A', 'M', 'O', 'R', 'K', 'L', 'M', 'R'],
    ['P', 'B', 'C', 'D', 'R', 'T', 'U', 'V'],
  ];
  static const Map<String, List<List<int>>> _info8x8 = {
    'AGUA': [[0, 0], [0, 1], [0, 2], [0, 3]],
    'SALUD': [[1, 1], [1, 2], [1, 3], [1, 4], [1, 5]],
    'VIDA': [[2, 1], [2, 2], [2, 3], [2, 4]],
    'PASO': [[4, 1], [4, 2], [4, 3], [4, 4]],
    'AMOR': [[6, 0], [6, 1], [6, 2], [6, 3]],
  };
  static const Map<String, Color> _colores8x8 = {
    'AGUA': Color(0xFF0284C7),
    'SALUD': Color(0xFF10B981),
    'VIDA': Color(0xFF0D9488),
    'PASO': Color(0xFFF97316),
    'AMOR': Color(0xFF10B981),
  };

  static const List<List<String>> _grid10x10 = [
    ['R', 'C', 'A', 'M', 'I', 'N', 'A', 'R', 'T', 'S'],
    ['B', 'E', 'D', 'F', 'G', 'H', 'I', 'J', 'K', 'C'],
    ['P', 'Q', 'S', 'A', 'L', 'U', 'D', 'L', 'M', 'A'],
    ['T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'A', 'B', 'L'],
    ['K', 'M', 'E', 'M', 'O', 'R', 'I', 'A', 'C', 'M'],
    ['N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'A'],
    ['F', 'G', 'C', 'O', 'R', 'A', 'Z', 'O', 'N', 'D'],
    ['H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'E'],
    ['Q', 'A', 'L', 'E', 'G', 'R', 'I', 'A', 'R', 'F'],
    ['S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'B', 'C'],
  ];
  static const Map<String, List<List<int>>> _info10x10 = {
    'CAMINAR': [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7]],
    'SALUD': [[2, 2], [2, 3], [2, 4], [2, 5], [2, 6]],
    'MEMORIA': [[4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6], [4, 7]],
    'CORAZON': [[6, 2], [6, 3], [6, 4], [6, 5], [6, 6], [6, 7], [6, 8]],
    'ALEGRIA': [[8, 1], [8, 2], [8, 3], [8, 4], [8, 5], [8, 6], [8, 7]],
    'CALMA': [[1, 9], [2, 9], [3, 9], [4, 9], [5, 9]],
  };
  static const Map<String, Color> _colores10x10 = {
    'CAMINAR': Color(0xFF0D9488),
    'SALUD': Color(0xFF10B981),
    'MEMORIA': Color(0xFF0284C7),
    'CORAZON': Color(0xFFEF4444),
    'ALEGRIA': Color(0xFFF59E0B),
    'CALMA': Color(0xFF06B6D4),
  };

  @override
  void initState() {
    super.initState();
    _iniciarNivel();
  }

  void _iniciarNivel() {
    setState(() {
      _palabrasEncontradas.clear();
      _inicioSeleccion = null;
      _finSeleccion = null;

      if (_dificultad == SopaDificultad.basico6x6) {
        _tamano = 6;
        _grid = _grid6x6;
        _palabrasInfo = _info6x6;
        _palabrasColores = _colores6x6;
      } else if (_dificultad == SopaDificultad.intermedio8x8) {
        _tamano = 8;
        _grid = _grid8x8;
        _palabrasInfo = _info8x8;
        _palabrasColores = _colores8x8;
      } else {
        _tamano = 10;
        _grid = _grid10x10;
        _palabrasInfo = _info10x10;
        _palabrasColores = _colores10x10;
      }
    });
  }

  Color? _colorDeCelda(int r, int c) {
    for (final entry in _palabrasInfo.entries) {
      if (_palabrasEncontradas.contains(entry.key)) {
        for (final pos in entry.value) {
          if (pos[0] == r && pos[1] == c) {
            return _palabrasColores[entry.key];
          }
        }
      }
    }
    return null;
  }

  List<int>? _posicionACelda(Offset localOffset, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    final double anchoCelda = size.width / _tamano;
    final double altoCelda = size.height / _tamano;

    final int col = (localOffset.dx / anchoCelda).floor().clamp(0, _tamano - 1);
    final int row = (localOffset.dy / altoCelda).floor().clamp(0, _tamano - 1);
    return [row, col];
  }

  void _evaluarLinea(int r1, int c1, int r2, int c2) {
    final diffR = r2 - r1;
    final diffC = c2 - c1;

    final isHorizontal = (r1 == r2);
    final isVertical = (c1 == c2);
    final isDiagonal = (diffR.abs() == diffC.abs());

    if (!isHorizontal && !isVertical && !isDiagonal) {
      setState(() {
        _inicioSeleccion = null;
        _finSeleccion = null;
      });
      return;
    }

    final stepR = diffR == 0 ? 0 : diffR.sign;
    final stepC = diffC == 0 ? 0 : diffC.sign;
    final length = (diffR != 0 ? diffR.abs() : diffC.abs()) + 1;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final currR = r1 + (stepR * i);
      final currC = c1 + (stepC * i);
      buffer.write(_grid[currR][currC]);
    }

    final palabraDirecta = buffer.toString();
    final palabraInversa = palabraDirecta.split('').reversed.join('');

    String? encontrada;
    for (final palabra in _palabrasInfo.keys) {
      if (!_palabrasEncontradas.contains(palabra)) {
        if (palabra == palabraDirecta || palabra == palabraInversa) {
          encontrada = palabra;
          break;
        }
      }
    }

    if (encontrada != null) {
      setState(() {
        _palabrasEncontradas.add(encontrada!);
        _inicioSeleccion = null;
        _finSeleccion = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨ ¡Encontraste: ', style: TextStyle(fontSize: 16)),
              Text(encontrada, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('! 🎉'),
            ],
          ),
          backgroundColor: _palabrasColores[encontrada] ?? AppColors.healthGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1500),
        ),
      );

      _verificarVictoria();
    } else {
      setState(() {
        _inicioSeleccion = null;
        _finSeleccion = null;
      });
    }
  }

  List<int>? _panDownCelda;

  void _onPanDown(DragDownDetails details) {
    final RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.globalToLocal(details.globalPosition);
    _panDownCelda = _posicionACelda(offset, box.size);
  }

  void _onPanStart(DragStartDetails details) {
    final RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.globalToLocal(details.globalPosition);
    final celda = _panDownCelda ?? _posicionACelda(offset, box.size);
    if (celda != null) {
      setState(() {
        _inicioSeleccion = celda;
        _finSeleccion = celda;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.globalToLocal(details.globalPosition);
    final celda = _posicionACelda(offset, box.size);
    if (celda != null && (celda[0] != _finSeleccion?[0] || celda[1] != _finSeleccion?[1])) {
      setState(() {
        _finSeleccion = celda;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_inicioSeleccion != null && _finSeleccion != null) {
      _evaluarLinea(_inicioSeleccion![0], _inicioSeleccion![1], _finSeleccion![0], _finSeleccion![1]);
    } else {
      setState(() {
        _inicioSeleccion = null;
        _finSeleccion = null;
      });
    }
  }

  void _onCeldaTap(int r, int c) {
    // También compatible con toque inicio + toque fin para máxima accesibilidad senior
    if (_inicioSeleccion == null) {
      setState(() {
        _inicioSeleccion = [r, c];
        _finSeleccion = [r, c];
      });
    } else {
      final r1 = _inicioSeleccion![0];
      final c1 = _inicioSeleccion![1];
      if (r1 == r && c1 == c) {
        setState(() {
          _inicioSeleccion = null;
          _finSeleccion = null;
        });
        return;
      }
      _evaluarLinea(r1, c1, r, c);
    }
  }

  void _verificarVictoria() async {
    if (_palabrasEncontradas.length == _palabrasInfo.length) {
      final puntos = _dificultad == SopaDificultad.basico6x6
          ? 120
          : _dificultad == SopaDificultad.intermedio8x8
              ? 250
              : 450;

      final nivelStr = _dificultad == SopaDificultad.basico6x6
          ? 'basico'
          : _dificultad == SopaDificultad.intermedio8x8
              ? 'intermedio'
              : 'avanzado';

      final pos = await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
            tipoJuego: 'Sopa de Letras',
            puntaje: puntos,
            nivelDificultad: nivelStr,
          );

      if (mounted) {
        VictoriaPuntajeDialog.mostrar(
          context: context,
          nombreJuego: 'Sopa de Letras (${_textoDificultad(_dificultad)})',
          puntaje: puntos,
          posicionTop: pos,
          mensajePersonalizado:
              '¡Hallaste todas las palabras! El rastreo visual continuo y la atención sostenida fortalecen tu agilidad mental.',
          onJugarDeNuevo: _iniciarNivel,
        );
      }
    }
  }

  String _textoDificultad(SopaDificultad d) {
    switch (d) {
      case SopaDificultad.basico6x6:
        return '6x6 Básico';
      case SopaDificultad.intermedio8x8:
        return '8x8 Intermedio';
      case SopaDificultad.avanzado10x10:
        return '10x10 Avanzado';
    }
  }

  bool _estaEnTrazoActual(int r, int c) {
    if (_inicioSeleccion == null || _finSeleccion == null) return false;
    final r1 = _inicioSeleccion![0];
    final c1 = _inicioSeleccion![1];
    final r2 = _finSeleccion![0];
    final c2 = _finSeleccion![1];

    final diffR = r2 - r1;
    final diffC = c2 - c1;

    final isHorizontal = (r1 == r2);
    final isVertical = (c1 == c2);
    final isDiagonal = (diffR.abs() == diffC.abs());

    if (!isHorizontal && !isVertical && !isDiagonal) {
      return (r == r1 && c == c1);
    }

    final stepR = diffR == 0 ? 0 : diffR.sign;
    final stepC = diffC == 0 ? 0 : diffC.sign;
    final length = (diffR != 0 ? diffR.abs() : diffC.abs()) + 1;

    for (int i = 0; i < length; i++) {
      if (r1 + (stepR * i) == r && c1 + (stepC * i) == c) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 190,
        leading: const BotonVolverJuegos(),
        title: const Text(
          '🔤 Sopa de Letras',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.healthGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reiniciar partida',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _iniciarNivel,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Selector de Dificultad ──
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('6x6 Básico (3 pal.)', SopaDificultad.basico6x6),
                      const SizedBox(width: 8),
                      _buildChip('8x8 Intermedio (5 pal.)', SopaDificultad.intermedio8x8),
                      const SizedBox(width: 8),
                      _buildChip('10x10 Avanzado (6 pal.)', SopaDificultad.avanzado10x10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Contador y Progreso ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Palabras a Encontrar:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.healthGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_palabrasEncontradas.length} / ${_palabrasInfo.length} halladas',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.healthGreen, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Checklist de Palabras (Solo informativo, no resuelve al pulsar) ──
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palabrasInfo.keys.map((p) {
                  final encontrada = _palabrasEncontradas.contains(p);
                  final color = _palabrasColores[p] ?? AppColors.primaryTeal;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: encontrada ? color : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: encontrada ? Colors.white : AppColors.textPrimary,
                        decoration: encontrada ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // ── Indicador Gestual y de Arrastre ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.healthGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text('👆', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Desliza tu dedo sobre la palabra (horizontal, vertical o diagonal) o toca el inicio y el final.',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Cuadrícula con Arrastre Continuo (GestureDetector Drag) ──
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.healthGreen, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GestureDetector(
                      key: _gridKey,
                      onPanDown: _onPanDown,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _tamano,
                          crossAxisSpacing: _tamano == 6 ? 6 : _tamano == 8 ? 4 : 3,
                          mainAxisSpacing: _tamano == 6 ? 6 : _tamano == 8 ? 4 : 3,
                        ),
                        itemCount: _tamano * _tamano,
                        itemBuilder: (context, index) {
                          final row = index ~/ _tamano;
                          final col = index % _tamano;
                          final letra = _grid[row][col];
                          final highlightColor = _colorDeCelda(row, col);
                          final estaEnTrazo = _estaEnTrazoActual(row, col);

                          return InkWell(
                            onTap: () => _onCeldaTap(row, col),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: estaEnTrazo
                                    ? Colors.amber.shade300
                                    : highlightColor ?? const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: estaEnTrazo
                                      ? Colors.amber.shade900
                                      : highlightColor ?? Colors.grey.shade300,
                                  width: estaEnTrazo ? 2.2 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  letra,
                                  style: TextStyle(
                                    fontSize: _tamano == 6 ? 24 : _tamano == 8 ? 19 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: estaEnTrazo
                                        ? Colors.brown.shade900
                                        : highlightColor != null
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, SopaDificultad dif) {
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
      selectedColor: AppColors.healthGreen,
      backgroundColor: Colors.white,
      onSelected: (val) {
        if (val) {
          setState(() => _dificultad = dif);
          _iniciarNivel();
        }
      },
    );
  }
}
