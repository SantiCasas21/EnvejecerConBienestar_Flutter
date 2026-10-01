import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/boton_volver_juegos.dart';
import '../widgets/victoria_puntaje_dialog.dart';

enum SimonDificultad { basico, intermedio, avanzado }

class SecuenciaLucesScreen extends ConsumerStatefulWidget {
  const SecuenciaLucesScreen({super.key});

  @override
  ConsumerState<SecuenciaLucesScreen> createState() => _SecuenciaLucesScreenState();
}

class _SecuenciaLucesScreenState extends ConsumerState<SecuenciaLucesScreen> {
  SimonDificultad _dificultad = SimonDificultad.intermedio;

  final Random _random = Random();
  final List<int> _secuencia = [];
  int _pasoUsuario = 0;
  int _rondaActual = 0;
  int _puntajeAcumulado = 0;

  bool _enPartida = false;
  bool _reproduciendo = false;
  int? _cuadranteActivo; // 0: Verde, 1: Azul, 2: Ámbar, 3: Rojo

  // Configuración de los 4 cuadrantes
  final List<Map<String, dynamic>> _cuadrantes = [
    {
      'id': 0,
      'nombre': 'Verde Esmeralda',
      'colorBase': const Color(0xFF10B981),
      'colorLuz': const Color(0xFF6EE7B7),
      'icono': '🌿',
    },
    {
      'id': 1,
      'nombre': 'Azul Índigo',
      'colorBase': const Color(0xFF6366F1),
      'colorLuz': const Color(0xFFA5B4FC),
      'icono': '💧',
    },
    {
      'id': 2,
      'nombre': 'Ámbar Cálido',
      'colorBase': const Color(0xFFF59E0B),
      'colorLuz': const Color(0xFFFDE68A),
      'icono': '☀️',
    },
    {
      'id': 3,
      'nombre': 'Coral Rubí',
      'colorBase': const Color(0xFFEF4444),
      'colorLuz': const Color(0xFFFCA5A5),
      'icono': '❤️',
    },
  ];

  int get _tiempoLuzMs {
    switch (_dificultad) {
      case SimonDificultad.basico:
        return 750;
      case SimonDificultad.intermedio:
        return 500;
      case SimonDificultad.avanzado:
        return 350;
    }
  }

  int get _tiempoPausaMs {
    switch (_dificultad) {
      case SimonDificultad.basico:
        return 280;
      case SimonDificultad.intermedio:
        return 200;
      case SimonDificultad.avanzado:
        return 160;
    }
  }

  void _iniciarJuego() {
    setState(() {
      _secuencia.clear();
      _rondaActual = 0;
      _puntajeAcumulado = 0;
      _pasoUsuario = 0;
      _enPartida = true;
      _cuadranteActivo = null;
    });
    _siguienteRonda();
  }

  void _siguienteRonda() {
    _secuencia.add(_random.nextInt(4));
    setState(() {
      _rondaActual++;
      _pasoUsuario = 0;
    });
    _reproducirSecuencia();
  }

  void _reproducirSecuencia() async {
    setState(() {
      _reproduciendo = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < _secuencia.length; i++) {
      if (!mounted || !_enPartida) return;

      final colorIndex = _secuencia[i];
      setState(() {
        _cuadranteActivo = colorIndex;
      });

      await Future.delayed(Duration(milliseconds: _tiempoLuzMs));

      if (!mounted || !_enPartida) return;
      setState(() {
        _cuadranteActivo = null;
      });

      await Future.delayed(Duration(milliseconds: _tiempoPausaMs));
    }

    if (mounted) {
      setState(() {
        _reproduciendo = false;
      });
    }
  }

  void _tocarCuadrante(int index) async {
    if (!_enPartida || _reproduciendo) return;

    // Destello de toque del usuario
    setState(() {
      _cuadranteActivo = index;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _cuadranteActivo == index) {
        setState(() => _cuadranteActivo = null);
      }
    });

    // Validar acierto
    if (index == _secuencia[_pasoUsuario]) {
      // Cálculo de puntos por paso calibrado:
      // Pasos 1 a 4: 10 pts
      // Pasos 5 a 8: 25 pts
      // Pasos 9+: 50 pts
      final pasoActual = _pasoUsuario + 1;
      int puntosPaso;
      if (pasoActual <= 4) {
        puntosPaso = 10;
      } else if (pasoActual <= 8) {
        puntosPaso = 25;
      } else {
        puntosPaso = 50;
      }
      _puntajeAcumulado += puntosPaso;

      _pasoUsuario++;

      // Completó la secuencia de esta ronda
      if (_pasoUsuario == _secuencia.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ¡Excelente! Ronda $_rondaActual completada'),
            duration: const Duration(milliseconds: 900),
            backgroundColor: AppColors.healthGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted && _enPartida) {
          _siguienteRonda();
        }
      }
    } else {
      // Error
      _finalizarPartida();
    }
  }

  void _finalizarPartida() async {
    setState(() {
      _enPartida = false;
      _reproduciendo = false;
      _cuadranteActivo = null;
    });

    final nivelStr = _dificultad == SimonDificultad.basico
        ? 'basico'
        : _dificultad == SimonDificultad.intermedio
            ? 'intermedio'
            : 'avanzado';

    final pos = await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
          tipoJuego: 'Secuencia de Luces',
          puntaje: _puntajeAcumulado,
          nivelDificultad: nivelStr,
        );

    if (mounted) {
      VictoriaPuntajeDialog.mostrar(
        context: context,
        nombreJuego: 'Secuencia de Luces (${_textoDificultad(_dificultad)})',
        puntaje: _puntajeAcumulado,
        posicionTop: pos,
        mensajePersonalizado:
            '¡Gran entrenamiento mental! Llegaste hasta la ronda $_rondaActual. Replicar secuencias visoespaciales activa la memoria de trabajo y la neuroplasticidad.',
        onJugarDeNuevo: _iniciarJuego,
      );
    }
  }

  String _textoDificultad(SimonDificultad d) {
    switch (d) {
      case SimonDificultad.basico:
        return 'Básico (Ritmo Suave)';
      case SimonDificultad.intermedio:
        return 'Intermedio (Ágil)';
      case SimonDificultad.avanzado:
        return 'Avanzado (Desafío)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leadingWidth: 190,
        leading: const BotonVolverJuegos(),
        title: const Text(
          '💡 Secuencia Luces',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryOrange,
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
                    _buildChip('Básico', SimonDificultad.basico),
                    const SizedBox(width: 8),
                    _buildChip('Intermedio', SimonDificultad.intermedio),
                    const SizedBox(width: 8),
                    _buildChip('Avanzado', SimonDificultad.avanzado),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Marcadores de Estado ──
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Text('🎯', style: TextStyle(fontSize: 16)),
                    label: Text('Ronda: $_rondaActual', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                  ),
                  Chip(
                    avatar: const Text('⭐', style: TextStyle(fontSize: 16)),
                    label: Text('Puntos: $_puntajeAcumulado', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    backgroundColor: AppColors.healthGreen.withValues(alpha: 0.18),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Banner de Estado del Juego ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _reproduciendo
                      ? Colors.amber.shade100
                      : _enPartida
                          ? AppColors.primaryLight.withValues(alpha: 0.4)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _reproduciendo ? Colors.amber.shade700 : AppColors.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_reproduciendo ? '👀' : _enPartida ? '👆' : '🎮', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _reproduciendo
                            ? 'Observa y memoriza el orden de las luces...'
                            : _enPartida
                                ? '¡Tu turno! Toca las luces en el mismo orden (${_pasoUsuario}/${_secuencia.length})'
                                : 'Pulsa el botón "Comenzar" para iniciar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _reproduciendo ? Colors.brown.shade900 : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Consola Circular de 4 Cuadrantes Luminosos ──
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380, maxHeight: 380),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cuadrantes 2x2
                        Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildBotonCuadrante(0, const BorderRadius.only(topLeft: Radius.circular(160)))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildBotonCuadrante(1, const BorderRadius.only(topRight: Radius.circular(160)))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildBotonCuadrante(2, const BorderRadius.only(bottomLeft: Radius.circular(160)))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildBotonCuadrante(3, const BorderRadius.only(bottomRight: Radius.circular(160)))),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Círculo Central con Display y Botón de Inicio
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryDark, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _enPartida ? null : _iniciarJuego,
                              borderRadius: BorderRadius.circular(60),
                              child: Center(
                                child: _enPartida
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('💡', style: TextStyle(fontSize: 22)),
                                          Text(
                                            'Ronda $_rondaActual',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      )
                                    : const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.play_arrow_rounded, size: 36, color: AppColors.primaryOrange),
                                          Text(
                                            'INICIAR',
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryOrange),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Guía para el Jugador ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.completedLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Text('🎯', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pon a prueba tu memoria inmediata. Cada ronda añade un nuevo destello a la secuencia. ¡Concéntrate y sigue el ritmo!',
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

  Widget _buildBotonCuadrante(int index, BorderRadius radius) {
    final conf = _cuadrantes[index];
    final bool activo = (_cuadranteActivo == index);
    final Color colorBase = conf['colorBase'] as Color;
    final Color colorLuz = conf['colorLuz'] as Color;

    return GestureDetector(
      onTap: () => _tocarCuadrante(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: activo ? colorLuz : colorBase,
          borderRadius: radius,
          border: Border.all(
            color: activo ? Colors.white : Colors.black12,
            width: activo ? 4 : 2,
          ),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: colorBase.withValues(alpha: 0.8),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            conf['icono'] as String,
            style: TextStyle(
              fontSize: activo ? 46 : 38,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, SimonDificultad dif) {
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
      selectedColor: AppColors.primaryOrange,
      backgroundColor: Colors.white,
      onSelected: (val) {
        if (val && !_enPartida) {
          setState(() => _dificultad = dif);
        } else if (_enPartida) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Termina la partida actual para cambiar la dificultad.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }
}
