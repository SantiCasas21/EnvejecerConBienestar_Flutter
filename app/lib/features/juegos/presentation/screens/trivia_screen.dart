import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/victoria_puntaje_dialog.dart';

class TriviaScreen extends ConsumerStatefulWidget {
  const TriviaScreen({super.key});

  @override
  ConsumerState<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends ConsumerState<TriviaScreen> {
  final List<Map<String, dynamic>> _preguntas = [
    {
      'pregunta': '¿Cuántos vasos de agua se recomienda tomar al día generalmente?',
      'opciones': [
        '2 a 3 vasos',
        '6 a 8 vasos',
        '15 a 20 vasos',
        'Solo cuando tenga sed',
      ],
      'correcta': 1,
      'explicacion': 'Mantenerse hidratado con 6 a 8 vasos previene mareos, favorece la función renal y mejora la memoria.',
    },
    {
      'pregunta': '¿Cuál de estos ejercicios es ideal para cuidar las articulaciones?',
      'opciones': [
        'Levantamiento pesado',
        'Caminata suave y natación',
        'Correr maratones',
        'Permanecer sentado todo el día',
      ],
      'correcta': 1,
      'explicacion': 'La caminata a paso regular y los ejercicios en agua fortalecen la musculatura sin impactar las rodillas ni la cadera.',
    },
    {
      'pregunta': '¿Por qué es vital tomar los medicamentos en el mismo horario?',
      'opciones': [
        'Para no olvidarlo',
        'Para mantener constante el nivel de medicina en el organismo',
        'No importa la hora, da igual',
        'Por simple costumbre',
      ],
      'correcta': 1,
      'explicacion': 'Cumplir los horarios garantiza que el efecto terapéutico de la medicina sea continuo, estable y seguro.',
    },
    {
      'pregunta': '¿Cuál es la mejor medida en casa para prevenir tropiezos y caídas?',
      'opciones': [
        'Caminar a oscuras para ahorrar luz',
        'Retirar tapetes sueltos y tener buena iluminación',
        'Usar calcetines lisos sin zapatos',
        'Dejar cables en los pasillos',
      ],
      'correcta': 1,
      'explicacion': 'La buena iluminación y pasillos libres de tapetes o cables reducen más del 80% de los accidentes domésticos.',
    },
    {
      'pregunta': '¿Qué hábito diario protege y estimula la salud del cerebro?',
      'opciones': [
        'Aprender cosas nuevas, leer y jugar memoria',
        'Aislarse de los amigos y familiares',
        'Dormir menos de 4 horas',
        'Ver televisión sin descanso',
      ],
      'correcta': 0,
      'explicacion': 'La curiosidad intelectual, la lectura y la interacción social generan nuevas conexiones neuronales (neuroplasticidad).',
    },
    {
      'pregunta': '¿Qué alimento es excelente aliado para la salud del corazón y huesos?',
      'opciones': [
        'Comidas ultraprocesadas con mucha sal',
        'Frutas frescas, verduras de hoja verde y legumbres',
        'Bebidas azucaradas',
        'Frituras a diario',
      ],
      'correcta': 1,
      'explicacion': 'Los antioxidantes, la fibra y los minerales de las frutas y vegetales protegen las arterias y nutren los huesos.',
    },
  ];

  int _indiceActual = 0;
  int _puntajeTotal = 0;
  int? _opcionSeleccionada;
  bool _respondido = false;

  void _responder(int index) {
    if (_respondido) return;

    setState(() {
      _opcionSeleccionada = index;
      _respondido = true;
      if (index == _preguntas[_indiceActual]['correcta']) {
        _puntajeTotal += 40;
      }
    });
  }

  void _siguiente() async {
    if (_indiceActual < _preguntas.length - 1) {
      setState(() {
        _indiceActual++;
        _opcionSeleccionada = null;
        _respondido = false;
      });
    } else {
      await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
            tipoJuego: 'Trivia de Salud',
            puntaje: _puntajeTotal,
          );

      if (mounted) {
        VictoriaPuntajeDialog.mostrar(
          context: context,
          nombreJuego: 'Trivia de Salud y Bienestar',
          puntaje: _puntajeTotal,
          mensajePersonalizado:
              '¡Completaste toda la trivia! El conocimiento sobre tu cuerpo y autocuidado es la mejor herramienta para vivir con plenitud.',
          onJugarDeNuevo: () {
            setState(() {
              _indiceActual = 0;
              _puntajeTotal = 0;
              _opcionSeleccionada = null;
              _respondido = false;
            });
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preg = _preguntas[_indiceActual];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '❓ Trivia de Salud',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.contactsBlue,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_puntajeTotal pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Progreso de Preguntas ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pregunta ${_indiceActual + 1} de ${_preguntas.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.contactsBlue),
                  ),
                  Text(
                    '${((_indiceActual + 1) / _preguntas.length * 100).toInt()}% completado',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_indiceActual + 1) / _preguntas.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.contactsBlue),
                ),
              ),
              const SizedBox(height: 20),

              // ── Tarjeta de Pregunta ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    preg['pregunta'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Opciones de Respuesta ──
              ...(preg['opciones'] as List<String>).asMap().entries.map((entry) {
                final idx = entry.key;
                final texto = entry.value;

                Color bgColor = Colors.white;
                Color borderColor = AppColors.border;
                Color textColor = AppColors.textPrimary;
                IconData iconData = Icons.radio_button_unchecked_rounded;

                if (_respondido) {
                  if (idx == preg['correcta']) {
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
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: _respondido ? null : () => _responder(idx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(iconData, color: borderColor, size: 26),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              texto,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: _respondido && idx == preg['correcta']
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

              // ── Explicación Médica ──
              if (_respondido) ...[
                const SizedBox(height: 8),
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
                          preg['explicacion'] as String,
                          style: TextStyle(fontSize: 15, color: Colors.blue.shade900, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _siguiente,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.contactsBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _indiceActual < _preguntas.length - 1
                          ? 'Siguiente Pregunta ➡️'
                          : 'Finalizar y Ver Puntaje 🏆',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
