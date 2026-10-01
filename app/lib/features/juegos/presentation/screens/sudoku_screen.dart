import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/boton_volver_juegos.dart';
import '../widgets/victoria_puntaje_dialog.dart';

enum SudokuDificultad { facil4x4, medio6x6, clasico9x9 }

class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key});

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
  SudokuDificultad _dificultad = SudokuDificultad.facil4x4;

  int _tamano = 4;
  int _bloqueFilas = 2;
  int _bloqueCols = 2;

  late List<List<int>> _solucion;
  late List<List<int>> _tableroInicial;
  late List<List<int>> _tableroUsuario;

  int? _filaSeleccionada;
  int? _colSeleccionada;

  int _pistasUsadas = 0;
  bool _juegoTerminado = false;

  int get _maxPistas {
    switch (_dificultad) {
      case SudokuDificultad.facil4x4:
        return 1;
      case SudokuDificultad.medio6x6:
        return 2;
      case SudokuDificultad.clasico9x9:
        return 3;
    }
  }

  int get _pistasRestantes => (_maxPistas - _pistasUsadas).clamp(0, _maxPistas);

  // ── PUZZLES PREDISEÑADOS ACCESIBLES ──

  static final List<Map<String, dynamic>> _puzzles4x4 = [
    {
      'sol': [
        [1, 2, 3, 4],
        [3, 4, 1, 2],
        [2, 1, 4, 3],
        [4, 3, 2, 1],
      ],
      'ini': [
        [1, 0, 3, 0],
        [0, 4, 0, 2],
        [2, 0, 4, 0],
        [0, 3, 0, 1],
      ],
    },
    {
      'sol': [
        [2, 1, 4, 3],
        [4, 3, 2, 1],
        [1, 2, 3, 4],
        [3, 4, 1, 2],
      ],
      'ini': [
        [0, 1, 4, 0],
        [4, 0, 0, 1],
        [1, 0, 0, 4],
        [0, 4, 1, 0],
      ],
    },
    {
      'sol': [
        [4, 3, 2, 1],
        [2, 1, 4, 3],
        [3, 4, 1, 2],
        [1, 2, 3, 4],
      ],
      'ini': [
        [4, 0, 0, 1],
        [0, 1, 4, 0],
        [0, 4, 1, 0],
        [1, 0, 0, 4],
      ],
    },
  ];

  static final List<Map<String, dynamic>> _puzzles6x6 = [
    {
      'sol': [
        [1, 2, 3, 4, 5, 6],
        [4, 5, 6, 1, 2, 3],
        [2, 3, 4, 5, 6, 1],
        [5, 6, 1, 2, 3, 4],
        [3, 4, 5, 6, 1, 2],
        [6, 1, 2, 3, 4, 5],
      ],
      'ini': [
        [1, 0, 3, 0, 5, 0],
        [0, 5, 0, 1, 0, 3],
        [2, 0, 4, 0, 6, 0],
        [0, 6, 0, 2, 0, 4],
        [3, 0, 5, 0, 1, 0],
        [0, 1, 0, 3, 0, 5],
      ],
    },
    {
      'sol': [
        [2, 3, 1, 5, 6, 4],
        [5, 6, 4, 2, 3, 1],
        [1, 2, 3, 4, 5, 6],
        [4, 5, 6, 1, 2, 3],
        [3, 1, 2, 6, 4, 5],
        [6, 4, 5, 3, 1, 2],
      ],
      'ini': [
        [2, 0, 1, 5, 0, 4],
        [0, 6, 0, 0, 3, 0],
        [1, 0, 3, 4, 0, 6],
        [4, 0, 6, 1, 0, 3],
        [0, 1, 0, 0, 4, 0],
        [6, 0, 5, 3, 0, 2],
      ],
    },
  ];

  static final List<Map<String, dynamic>> _puzzles9x9 = [
    {
      'sol': [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ],
      'ini': [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarNuevaPartida();
  }

  void _iniciarNuevaPartida() {
    Map<String, dynamic> puzzle;
    if (_dificultad == SudokuDificultad.facil4x4) {
      _tamano = 4;
      _bloqueFilas = 2;
      _bloqueCols = 2;
      final idx = DateTime.now().millisecondsSinceEpoch % _puzzles4x4.length;
      puzzle = _puzzles4x4[idx];
    } else if (_dificultad == SudokuDificultad.medio6x6) {
      _tamano = 6;
      _bloqueFilas = 2;
      _bloqueCols = 3;
      final idx = DateTime.now().millisecondsSinceEpoch % _puzzles6x6.length;
      puzzle = _puzzles6x6[idx];
    } else {
      _tamano = 9;
      _bloqueFilas = 3;
      _bloqueCols = 3;
      final idx = DateTime.now().millisecondsSinceEpoch % _puzzles9x9.length;
      puzzle = _puzzles9x9[idx];
    }

    final solRaw = puzzle['sol'] as List<List<int>>;
    final iniRaw = puzzle['ini'] as List<List<int>>;

    setState(() {
      _solucion = List.generate(_tamano, (r) => List<int>.from(solRaw[r]));
      _tableroInicial = List.generate(_tamano, (r) => List<int>.from(iniRaw[r]));
      _tableroUsuario = List.generate(_tamano, (r) => List<int>.from(iniRaw[r]));
      _filaSeleccionada = null;
      _colSeleccionada = null;
      _pistasUsadas = 0;
      _juegoTerminado = false;
    });
  }

  void _seleccionarCelda(int r, int c) {
    setState(() {
      _filaSeleccionada = r;
      _colSeleccionada = c;
    });
  }

  void _ingresarNumero(int numero) {
    if (_filaSeleccionada == null || _colSeleccionada == null || _juegoTerminado) return;
    final r = _filaSeleccionada!;
    final c = _colSeleccionada!;

    if (_tableroInicial[r][c] != 0) return;

    setState(() {
      _tableroUsuario[r][c] = numero;
    });

    _verificarVictoria();
  }

  void _borrarNumero() {
    if (_filaSeleccionada == null || _colSeleccionada == null || _juegoTerminado) return;
    final r = _filaSeleccionada!;
    final c = _colSeleccionada!;

    if (_tableroInicial[r][c] != 0) return;

    setState(() {
      _tableroUsuario[r][c] = 0;
    });
  }

  void _solicitarPistaInformativa() {
    if (_juegoTerminado) return;

    if (_pistasRestantes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Has utilizado todas las pistas permitidas para este nivel ($_maxPistas/$_maxPistas). ¡Confía en tu lógica!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Identificar la celda a orientar: si el usuario tiene una celda vacía seleccionada, la usamos; si no, buscamos la primera vacía
    int targetR = -1;
    int targetC = -1;

    if (_filaSeleccionada != null && _colSeleccionada != null && _tableroUsuario[_filaSeleccionada!][_colSeleccionada!] == 0) {
      targetR = _filaSeleccionada!;
      targetC = _colSeleccionada!;
    } else {
      for (int r = 0; r < _tamano; r++) {
        for (int c = 0; c < _tamano; c++) {
          if (_tableroUsuario[r][c] == 0) {
            targetR = r;
            targetC = c;
            break;
          }
        }
        if (targetR != -1) break;
      }
    }

    if (targetR == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡No hay casillas vacías pendientes!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final valorCorrecto = _solucion[targetR][targetC];

    // Construir explicación pedagógica basada en los números presentes en fila, columna o bloque
    final startRow = (targetR ~/ _bloqueFilas) * _bloqueFilas;
    final startCol = (targetC ~/ _bloqueCols) * _bloqueCols;
    final Set<int> enBloque = {};
    for (int rf = startRow; rf < startRow + _bloqueFilas; rf++) {
      for (int cf = startCol; cf < startCol + _bloqueCols; cf++) {
        final val = _tableroUsuario[rf][cf];
        if (val != 0 && val != valorCorrecto) enBloque.add(val);
      }
    }

    String explicacion = '';
    if (enBloque.isNotEmpty) {
      explicacion = 'En este bloque ya están presentes los números ${enBloque.toList()..sort()}. Por la regla de descarte y no repetición, esta casilla corresponde al número $valorCorrecto.';
    } else {
      explicacion = 'Analizando la fila ${targetR + 1} y la columna ${targetC + 1}, el único número que no se repite y respeta el patrón es el $valorCorrecto.';
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('💡', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Text('Pista Deductiva', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryTeal)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Casilla: Fila ${targetR + 1}, Columna ${targetC + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              explicacion,
              style: const TextStyle(fontSize: 15, height: 1.35, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Pistas restantes después de aplicar: ${_pistasRestantes - 1} de $_maxPistas',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              setState(() {
                _tableroUsuario[targetR][targetC] = valorCorrecto;
                _filaSeleccionada = targetR;
                _colSeleccionada = targetC;
                _pistasUsadas++;
              });
              _verificarVictoria();
            },
            child: Text('Colocar el $valorCorrecto', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _tieneConflicto(int r, int c) {
    final valor = _tableroUsuario[r][c];
    if (valor == 0) return false;

    // Verificar fila
    for (int col = 0; col < _tamano; col++) {
      if (col != c && _tableroUsuario[r][col] == valor) return true;
    }

    // Verificar columna
    for (int fila = 0; fila < _tamano; fila++) {
      if (fila != r && _tableroUsuario[fila][c] == valor) return true;
    }

    // Verificar bloque
    final startRow = (r ~/ _bloqueFilas) * _bloqueFilas;
    final startCol = (c ~/ _bloqueCols) * _bloqueCols;

    for (int rf = startRow; rf < startRow + _bloqueFilas; rf++) {
      for (int cf = startCol; cf < startCol + _bloqueCols; cf++) {
        if ((rf != r || cf != c) && _tableroUsuario[rf][cf] == valor) {
          return true;
        }
      }
    }

    return false;
  }

  void _verificarVictoria() async {
    bool lleno = true;
    bool correcto = true;

    for (int r = 0; r < _tamano; r++) {
      for (int c = 0; c < _tamano; c++) {
        if (_tableroUsuario[r][c] == 0) {
          lleno = false;
          break;
        }
        if (_tableroUsuario[r][c] != _solucion[r][c]) {
          correcto = false;
        }
      }
      if (!lleno) break;
    }

    if (lleno && correcto && !_juegoTerminado) {
      _juegoTerminado = true;

      int puntosBase;
      int descuentoPorPista;
      if (_dificultad == SudokuDificultad.facil4x4) {
        puntosBase = 120;
        descuentoPorPista = 15;
      } else if (_dificultad == SudokuDificultad.medio6x6) {
        puntosBase = 280;
        descuentoPorPista = 20;
      } else {
        puntosBase = 500;
        descuentoPorPista = 25;
      }

      final penalizacionPistas = _pistasUsadas * descuentoPorPista;
      final puntajeFinal = (puntosBase - penalizacionPistas).clamp(50, puntosBase);

      final nivelStr = _dificultad == SudokuDificultad.facil4x4
          ? 'basico'
          : _dificultad == SudokuDificultad.medio6x6
              ? 'intermedio'
              : 'avanzado';

      final pos = await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
            tipoJuego: 'Sudoku',
            puntaje: puntajeFinal,
            nivelDificultad: nivelStr,
          );

      if (mounted) {
        VictoriaPuntajeDialog.mostrar(
          context: context,
          nombreJuego: 'Sudoku (${_textoDificultad(_dificultad)})',
          puntaje: puntajeFinal,
          posicionTop: pos,
          mensajePersonalizado:
              '¡Completaste el Sudoku exitosamente! El razonamiento lógico y los patrones numéricos son un escudo protector para tu memoria.',
          onJugarDeNuevo: _iniciarNuevaPartida,
        );
      }
    }
  }

  String _textoDificultad(SudokuDificultad d) {
    switch (d) {
      case SudokuDificultad.facil4x4:
        return '4x4 Básico';
      case SudokuDificultad.medio6x6:
        return '6x6 Intermedio';
      case SudokuDificultad.clasico9x9:
        return '9x9 Avanzado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final celdaSeleccionada = (_filaSeleccionada != null && _colSeleccionada != null)
        ? _tableroUsuario[_filaSeleccionada!][_colSeleccionada!]
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 190,
        leading: const BotonVolverJuegos(),
        title: const Text(
          '🔢 Sudoku',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reiniciar partida',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _iniciarNuevaPartida,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // ── Selector de Dificultad ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDificultadChip('4x4 Básico', SudokuDificultad.facil4x4, '🧩'),
                    const SizedBox(width: 8),
                    _buildDificultadChip('6x6 Intermedio', SudokuDificultad.medio6x6, '⚡'),
                    const SizedBox(width: 8),
                    _buildDificultadChip('9x9 Avanzado', SudokuDificultad.clasico9x9, '🎯'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Barra de Pistas con Límite Estricto y Explicación ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _pistasRestantes > 0 ? AppColors.primaryLight.withValues(alpha: 0.5) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pistas restantes: $_pistasRestantes / $_maxPistas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _pistasRestantes > 0 ? AppColors.primaryTeal : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pistasRestantes > 0 ? _solicitarPistaInformativa : null,
                    icon: const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                    label: const Text('💡 Pedir Pista', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.brown.shade900,
                      side: BorderSide(color: _pistasRestantes > 0 ? Colors.amber.shade400 : Colors.grey.shade300),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Tablero de Sudoku ──
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.primaryTeal, width: 2.5),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Column(
                      children: List.generate(_tamano, (r) {
                        return Expanded(
                          child: Row(
                            children: List.generate(_tamano, (c) {
                              final valor = _tableroUsuario[r][c];
                              final esFijo = _tableroInicial[r][c] != 0;
                              final estaSeleccionada = (_filaSeleccionada == r && _colSeleccionada == c);
                              final tieneConflicto = _tieneConflicto(r, c);

                              final mismaFilaOColumna = (_filaSeleccionada == r || _colSeleccionada == c);
                              final mismoNumero = (celdaSeleccionada > 0 && valor == celdaSeleccionada);

                              Color bgColor = Colors.white;
                              if (tieneConflicto) {
                                bgColor = const Color(0xFFFEE2E2);
                              } else if (estaSeleccionada) {
                                bgColor = const Color(0xFFBAE6FD);
                              } else if (mismoNumero) {
                                bgColor = const Color(0xFFE0F2FE);
                              } else if (mismaFilaOColumna) {
                                bgColor = const Color(0xFFF8FAFC);
                              }

                              final borderRight = ((c + 1) % _bloqueCols == 0 && c != _tamano - 1)
                                  ? const BorderSide(color: AppColors.primaryTeal, width: 2.5)
                                  : const BorderSide(color: Color(0xFFE2E8F0), width: 1);

                              final borderBottom = ((r + 1) % _bloqueFilas == 0 && r != _tamano - 1)
                                  ? const BorderSide(color: AppColors.primaryTeal, width: 2.5)
                                  : const BorderSide(color: Color(0xFFE2E8F0), width: 1);

                              final fontSize = _tamano == 4 ? 32.0 : _tamano == 6 ? 26.0 : 20.0;

                              return Expanded(
                                child: InkWell(
                                  onTap: () => _seleccionarCelda(r, c),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      border: Border(
                                        right: borderRight,
                                        bottom: borderBottom,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        valor == 0 ? '' : valor.toString(),
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: esFijo ? FontWeight.w900 : FontWeight.bold,
                                          color: tieneConflicto
                                              ? AppColors.emergencyRed
                                              : esFijo
                                                  ? AppColors.textPrimary
                                                  : AppColors.primaryTeal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Teclado Numérico Dinámico ──
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...List.generate(_tamano, (i) {
                      final numero = i + 1;
                      return SizedBox(
                        width: _tamano == 4 ? 80 : _tamano == 6 ? 56 : 42,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _ingresarNumero(numero),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                          child: Text(
                            numero.toString(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                    SizedBox(
                      width: _tamano == 4 ? 80 : 64,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _borrarNumero,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.backspace_outlined, color: AppColors.emergencyRed, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Guía Didáctica ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Completa la cuadrícula sin repetir números en filas, columnas ni bloques. Las pistas te explican la técnica de deducción.',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDificultadChip(String label, SudokuDificultad dif, String emoji) {
    final selected = _dificultad == dif;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      selected: selected,
      selectedColor: AppColors.primaryTeal,
      backgroundColor: Colors.white,
      onSelected: (val) {
        if (val) {
          setState(() => _dificultad = dif);
          _iniciarNuevaPartida();
        }
      },
    );
  }
}
