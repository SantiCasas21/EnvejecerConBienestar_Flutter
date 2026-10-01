import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../data/datasources/trivia_cultura_general_data.dart';
import '../providers/juegos_provider.dart';
import '../widgets/boton_volver_juegos.dart';
import '../widgets/victoria_puntaje_dialog.dart';

class TriviaScreen extends ConsumerStatefulWidget {
  const TriviaScreen({super.key});

  @override
  ConsumerState<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends ConsumerState<TriviaScreen> {
  bool _enRecibidor = true;
  String _categoriaSeleccionada = 'geografia_historia';
  List<PreguntaTrivia> _preguntasPartida = [];
  int _indiceActual = 0;
  int _puntajeTotal = 0;
  int? _opcionSeleccionada;
  bool _respondido = false;
  int _pistasDisponibles = 1;

  final Map<String, Map<String, dynamic>> _categoriasConfig = {
    'deportes': {
      'nombre': 'Deportes',
      'icono': '⚽',
      'descripcion': 'Fútbol, ciclismo, tenis, olimpiadas y récords',
      'color': const Color(0xFF0D9488),
    },
    'arte_cultura': {
      'nombre': 'Arte y Cultura',
      'icono': '🎨',
      'descripcion': 'Pintura, música, cine, literatura y tradiciones',
      'color': const Color(0xFFF59E0B),
    },
    'geografia_historia': {
      'nombre': 'Geografía e Historia',
      'icono': '🌍',
      'descripcion': 'Países, capitales, monumentos y grandes civilizaciones',
      'color': const Color(0xFF0284C7),
    },
    'salud_bienestar': {
      'nombre': 'Salud y Bienestar',
      'icono': '🍎',
      'descripcion': 'Nutrición, hábitos de vida, cuerpo humano y vitalidad',
      'color': const Color(0xFF10B981),
    },
    'ciencia_naturaleza': {
      'nombre': 'Ciencia y Naturaleza',
      'icono': '🔬',
      'descripcion': 'Animales, universo, inventos y descubrimientos',
      'color': const Color(0xFF6366F1),
    },
  };

  void _iniciarPartidaConCategoria(String cat) {
    setState(() {
      _categoriaSeleccionada = cat;
      _preguntasPartida = TriviaCulturaGeneralData.obtenerPreguntasPorCategoria(cat, limite: 10);
      _indiceActual = 0;
      _puntajeTotal = 0;
      _opcionSeleccionada = null;
      _respondido = false;
      _pistasDisponibles = 1;
      _enRecibidor = false;
    });
  }

  void _iniciarPartida() {
    _iniciarPartidaConCategoria(_categoriaSeleccionada);
  }

  void _solicitarPista() {
    if (_pistasDisponibles <= 0 || _respondido || _preguntasPartida.isEmpty) return;

    final preg = _preguntasPartida[_indiceActual];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('💡', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Text(
              'Pista de Contexto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.contactsBlue),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta pista te brinda un dato deductivo para razonar la respuesta correcta sin revelarla:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                preg.pista,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.contactsBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _pistasDisponibles--;
              });
            },
            child: const Text('¡Entendido!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _responder(int index) {
    if (_respondido || _preguntasPartida.isEmpty) return;

    final preg = _preguntasPartida[_indiceActual];
    setState(() {
      _opcionSeleccionada = index;
      _respondido = true;
      if (index == preg.correcta) {
        _puntajeTotal += 25;
      }
    });
  }

  void _siguiente() async {
    if (_indiceActual < _preguntasPartida.length - 1) {
      setState(() {
        _indiceActual++;
        _opcionSeleccionada = null;
        _respondido = false;
      });
    } else {
      final bonusMaestria = (_pistasDisponibles == 1) ? 50 : 0;
      final puntajeFinal = _puntajeTotal + bonusMaestria;

      final pos = await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
            tipoJuego: 'Trivia de Cultura General',
            puntaje: puntajeFinal,
            nivelDificultad: 'intermedio',
          );

      if (mounted) {
        final catNombre = _categoriasConfig[_categoriaSeleccionada]?['nombre'] ?? 'Cultura General';
        VictoriaPuntajeDialog.mostrar(
          context: context,
          nombreJuego: 'Trivia ($catNombre)',
          puntaje: puntajeFinal,
          posicionTop: pos,
          mensajePersonalizado:
              '¡Completaste las 10 preguntas de la trivia! Ejercitar la memoria semántica y el saber universal fortalece la reserva cognitiva.',
          onJugarDeNuevo: _iniciarPartida,
          onCambiarModo: () {
            setState(() {
              _enRecibidor = true;
            });
          },
          textoCambiarModo: 'Elegir otra Categoría',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enRecibidor) {
      return _buildRecibidor(context);
    }
    return _buildCuestionario(context);
  }

  /// ── Pantalla de Recibidor / Selección de Categoría ──
  Widget _buildRecibidor(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 190,
        leading: const BotonVolverJuegos(),
        title: const Text(
          '🧠 Trivia de Cultura',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Banner Explicativo ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('📚', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Elige una Categoría de Trivia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cada ronda consta de 10 preguntas desafiantes con 1 pista deductiva para ejercitar tu memoria semántica.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Categorías Disponibles:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // ── 5 Tarjetas Grandes de Categorías ──
              ..._categoriasConfig.entries.map((entry) {
                final key = entry.key;
                final info = entry.value;
                final color = info['color'] as Color;
                final nombre = info['nombre'] as String;
                final icono = info['icono'] as String;
                final descripcion = info['descripcion'] as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2.5,
                  child: InkWell(
                    onTap: () => _iniciarPartidaConCategoria(key),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              icono,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  descripcion,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '10 preguntas • Hasta 300 pts',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// ── Cuestionario de la Ronda Activa ──
  Widget _buildCuestionario(BuildContext context) {
    final catInfo = _categoriasConfig[_categoriaSeleccionada] ?? {};
    final catColor = catInfo['color'] as Color? ?? AppColors.primaryTeal;
    final catNombre = catInfo['nombre'] as String? ?? 'Trivia';
    final catIcono = catInfo['icono'] as String? ?? '🧠';

    if (_preguntasPartida.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 190,
          leading: const BotonVolverJuegos(),
          title: Text(catNombre),
          backgroundColor: catColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final preg = _preguntasPartida[_indiceActual];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 190,
        leading: const BotonVolverJuegos(),
        title: Text(
          '$catIcono $catNombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: catColor,
        foregroundColor: Colors.white,
        actions: [
          // Botón para volver al recibidor de categorías
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.grid_view_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Categorías',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white),
            ),
            onPressed: () {
              setState(() {
                _enRecibidor = true;
              });
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Reiniciar partida',
            icon: const Icon(Icons.refresh_rounded, size: 26),
            onPressed: _iniciarPartida,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_puntajeTotal pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Barra de Progreso y Pista Contextual ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pregunta ${_indiceActual + 1} de ${_preguntasPartida.length}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: catColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_pistasDisponibles > 0 && !_respondido) ? _solicitarPista : null,
                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                    label: Text(
                      _pistasDisponibles > 0 ? '💡 Pista (1)' : 'Sin pistas',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.brown.shade900,
                      side: BorderSide(color: _pistasDisponibles > 0 ? Colors.amber.shade400 : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_indiceActual + 1) / _preguntasPartida.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(catColor),
                ),
              ),
              const SizedBox(height: 16),

              // ── Tarjeta de la Pregunta ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2.5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    preg.pregunta,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Opciones de Respuesta ──
              ...preg.opciones.asMap().entries.map((entry) {
                final idx = entry.key;
                final texto = entry.value;

                Color bgColor = Colors.white;
                Color borderColor = AppColors.border;
                Color textColor = AppColors.textPrimary;
                IconData iconData = Icons.radio_button_unchecked_rounded;

                if (_respondido) {
                  if (idx == preg.correcta) {
                    bgColor = Colors.green.shade50;
                    borderColor = AppColors.healthGreen;
                    textColor = Colors.green.shade900;
                    iconData = Icons.check_circle_rounded;
                  } else if (idx == _opcionSeleccionada) {
                    bgColor = Colors.red.shade50;
                    borderColor = AppColors.emergencyRed;
                    textColor = Colors.red.shade900;
                    iconData = Icons.cancel_rounded;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: _respondido ? null : () => _responder(idx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(iconData, color: borderColor, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              texto,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _respondido && idx == preg.correcta
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // ── Explicación y Botón Continuar ──
              if (_respondido) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.contactsBlue, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          preg.explicacion,
                          style: TextStyle(fontSize: 14, color: Colors.blue.shade900, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _siguiente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: catColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _indiceActual < _preguntasPartida.length - 1
                          ? 'Siguiente Pregunta ➡️'
                          : 'Finalizar y Ver Récord 🏆',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
