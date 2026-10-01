import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/victoria_puntaje_dialog.dart';

enum SecuenciaDificultad { basico, intermedio, avanzado }

class OrdenarSecuenciaScreen extends ConsumerStatefulWidget {
  const OrdenarSecuenciaScreen({super.key});

  @override
  ConsumerState<OrdenarSecuenciaScreen> createState() => _OrdenarSecuenciaScreenState();
}

class _OrdenarSecuenciaScreenState extends ConsumerState<OrdenarSecuenciaScreen> {
  SecuenciaDificultad _dificultad = SecuenciaDificultad.intermedio;

  // ── BANCOS DE RUTINAS POR NIVEL ──

  // Nivel Básico (3 pasos)
  static final List<Map<String, dynamic>> _rutinasBasico = [
    {
      'titulo': 'Lavado Correcto de Manos',
      'icono': '🧼',
      'pasos': [
        'Mojar las manos con agua limpia de la llave',
        'Frotar con suficiente jabón durante 20 segundos',
        'Enjuagar bien con abundante agua y secar con toalla limpia',
      ],
    },
    {
      'titulo': 'Hidratación al Despertar',
      'icono': '💧',
      'pasos': [
        'Ir a la cocina y tomar un vaso limpio',
        'Llenar el vaso con agua fresca a temperatura ambiente',
        'Beber con calma a sorbos para despertar el organismo',
      ],
    },
    {
      'titulo': 'Prepararse para Caminar',
      'icono': '👟',
      'pasos': [
        'Ponerse calzado cómodo y antideslizante',
        'Tomar las llaves de casa y el teléfono móvil',
        'Salir con paso tranquilo a disfrutar del aire libre',
      ],
    },
  ];

  // Nivel Intermedio (4 pasos)
  static final List<Map<String, dynamic>> _rutinasIntermedio = [
    {
      'titulo': 'Toma Segura de Medicamentos',
      'icono': '💊',
      'pasos': [
        'Lavarse las manos con agua y jabón',
        'Verificar el nombre y dosis de la medicina en la receta',
        'Ingerir el medicamento con abundante agua fresca',
        'Registrar la toma realizada en la aplicación',
      ],
    },
    {
      'titulo': 'Preparar una Infusión Relajante',
      'icono': '🍵',
      'pasos': [
        'Poner a calentar agua fresca en la tetera u olla',
        'Colocar la bolsita de manzanilla o tilo en la taza',
        'Verter el agua caliente y dejar reposar 5 minutos tapado',
        'Disfrutar con calma a temperatura tibia sin azúcar',
      ],
    },
    {
      'titulo': 'Higiene y Buen Dormir',
      'icono': '🌙',
      'pasos': [
        'Cenar algo ligero 2 horas antes de acostarse',
        'Apagar pantallas de televisión y teléfono celular',
        'Cepillarse los dientes suavemente',
        'Acomodarse en la cama practicando respiraciones profundas',
      ],
    },
  ];

  // Nivel Avanzado (5 pasos)
  static final List<Map<String, dynamic>> _rutinasAvanzado = [
    {
      'titulo': 'Rutina Matutina de Vitalidad',
      'icono': '🌅',
      'pasos': [
        'Despertar y estirar suavemente brazos y piernas en la cama',
        'Beber un vaso de agua fresca para rehidratar el cuerpo',
        'Realizar el aseo personal y cepillado dental',
        'Desayunar alimentos nutritivos con frutas y fibra',
        'Realizar una caminata suave de 20 minutos bajo el sol matutino',
      ],
    },
    {
      'titulo': 'Medición Correcta de Presión Arterial',
      'icono': '🩺',
      'pasos': [
        'Reposar sentado y en silencio durante 5 minutos previos',
        'Colocar el brazalete en el brazo a la altura del corazón',
        'Encender el tensiómetro manteniéndose quieto y sin hablar',
        'Anotar los valores de presión y pulso con fecha y hora',
        'Guardar el dispositivo en su estuche en lugar seco',
      ],
    },
    {
      'titulo': 'Preparación para Cita Médica',
      'icono': '🏥',
      'pasos': [
        'Reunir documentos de identidad y órdenes médicas previas',
        'Tomar la medicación habitual que corresponda al horario',
        'Llevar una botella con agua y un refrigerio saludable',
        'Salir de casa con tiempo suficiente para evitar prisas y estrés',
        'Anunciarse en la ventanilla del centro médico con amabilidad',
      ],
    },
  ];

  late List<Map<String, dynamic>> _rutinasActuales;
  int _rutinaIndex = 0;
  List<String> _pasosMezclados = [];
  List<String> _pasosUsuario = [];
  int _puntajeAcumulado = 0;

  @override
  void initState() {
    super.initState();
    _iniciarNivel();
  }

  void _iniciarNivel() {
    setState(() {
      _rutinaIndex = 0;
      _puntajeAcumulado = 0;
      if (_dificultad == SecuenciaDificultad.basico) {
        _rutinasActuales = _rutinasBasico;
      } else if (_dificultad == SecuenciaDificultad.intermedio) {
        _rutinasActuales = _rutinasIntermedio;
      } else {
        _rutinasActuales = _rutinasAvanzado;
      }
    });
    _cargarRutina();
  }

  void _cargarRutina() {
    final pasosOriginales = List<String>.from(_rutinasActuales[_rutinaIndex]['pasos']);
    final ordenados = List<String>.from(pasosOriginales);
    // Asegurar que quede mezclado
    ordenados.shuffle();

    setState(() {
      _pasosMezclados = ordenados;
      _pasosUsuario = [];
    });
  }

  void _seleccionarPaso(String paso) {
    if (_pasosUsuario.contains(paso)) {
      setState(() => _pasosUsuario.remove(paso));
    } else {
      setState(() => _pasosUsuario.add(paso));
    }
  }

  void _verificar() async {
    final pasosOriginales = List<String>.from(_rutinasActuales[_rutinaIndex]['pasos']);
    int aciertos = 0;

    for (int i = 0; i < _pasosUsuario.length; i++) {
      if (i < pasosOriginales.length && _pasosUsuario[i] == pasosOriginales[i]) {
        aciertos++;
      }
    }

    final esPerfecto = _pasosUsuario.length == pasosOriginales.length && aciertos == pasosOriginales.length;
    final puntosBase = _dificultad == SecuenciaDificultad.basico
        ? 35
        : _dificultad == SecuenciaDificultad.intermedio
            ? 60
            : 100;
    final puntos = esPerfecto ? puntosBase : (aciertos * 10);
    _puntajeAcumulado += puntos;

    if (_rutinaIndex < _rutinasActuales.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esPerfecto ? '✨ ¡Secuencia perfecta! +$puntos pts' : '👍 ¡Bien intentado! Obtuviste +$puntos pts',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: esPerfecto ? AppColors.healthGreen : AppColors.primaryOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _rutinaIndex++);
      _cargarRutina();
    } else {
      final nivelStr = _dificultad == SecuenciaDificultad.basico
          ? 'basico'
          : _dificultad == SecuenciaDificultad.intermedio
              ? 'intermedio'
              : 'avanzado';

      final pos = await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
            tipoJuego: 'Ordenar Secuencia',
            puntaje: _puntajeAcumulado,
            nivelDificultad: nivelStr,
          );

      if (mounted) {
        VictoriaPuntajeDialog.mostrar(
          context: context,
          nombreJuego: 'Ordenar Secuencias (${_textoDificultad(_dificultad)})',
          puntaje: _puntajeAcumulado,
          posicionTop: pos,
          mensajePersonalizado:
              '¡Completaste todas las secuencias cotidianas! Organizar pasos lógicos ejercita las funciones ejecutivas del lóbulo frontal.',
          onJugarDeNuevo: _iniciarNivel,
        );
      }
    }
  }

  String _textoDificultad(SecuenciaDificultad d) {
    switch (d) {
      case SecuenciaDificultad.basico:
        return 'Básico (3 Pasos)';
      case SecuenciaDificultad.intermedio:
        return 'Intermedio (4 Pasos)';
      case SecuenciaDificultad.avanzado:
        return 'Avanzado (5 Pasos)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rutina = _rutinasActuales[_rutinaIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24),
          tooltip: 'Volver a Juegos',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/juegos');
            }
          },
        ),
        title: const Text(
          '📋 Ordenar Secuencia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.primaryOrange,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Selector de Dificultad ──
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('Básico (3 pasos)', SecuenciaDificultad.basico),
                      const SizedBox(width: 8),
                      _buildChip('Intermedio (4 pasos)', SecuenciaDificultad.intermedio),
                      const SizedBox(width: 8),
                      _buildChip('Avanzado (5 pasos)', SecuenciaDificultad.avanzado),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Encabezado de Rutina ──
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(rutina['icono'] as String, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rutina ${_rutinaIndex + 1} de ${_rutinasActuales.length}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              rutina['titulo'] as String,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_puntajeAcumulado pts',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Toca los pasos en el orden cronológico correcto:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              // ── Opciones Disponibles ──
              Expanded(
                child: ListView.builder(
                  itemCount: _pasosMezclados.length,
                  itemBuilder: (context, index) {
                    final paso = _pasosMezclados[index];
                    final seleccionado = _pasosUsuario.contains(paso);
                    final ordenIndex = _pasosUsuario.indexOf(paso) + 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: seleccionado ? AppColors.primaryOrange : AppColors.border,
                          width: seleccionado ? 2 : 1,
                        ),
                      ),
                      color: seleccionado ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () => _seleccionarPaso(paso),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: seleccionado ? AppColors.primaryOrange : Colors.grey.shade200,
                          foregroundColor: seleccionado ? Colors.white : Colors.black87,
                          child: Text(
                            seleccionado ? '$ordenIndex' : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        title: Text(
                          paso,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          seleccionado ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: seleccionado ? AppColors.primaryOrange : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Botón Verificar Secuencia ──
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _pasosUsuario.length == _pasosMezclados.length ? _verificar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.healthGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _pasosUsuario.length == _pasosMezclados.length
                        ? 'Verificar Orden y Continuar'
                        : 'Selecciona los ${_pasosMezclados.length - _pasosUsuario.length} pasos restantes',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, SecuenciaDificultad dif) {
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
        if (val) {
          setState(() => _dificultad = dif);
          _iniciarNivel();
        }
      },
    );
  }
}
