import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/juegos_provider.dart';
import '../widgets/victoria_puntaje_dialog.dart';

class OrdenarSecuenciaScreen extends ConsumerStatefulWidget {
  const OrdenarSecuenciaScreen({super.key});

  @override
  ConsumerState<OrdenarSecuenciaScreen> createState() =>
      _OrdenarSecuenciaScreenState();
}

class _OrdenarSecuenciaScreenState
    extends ConsumerState<OrdenarSecuenciaScreen> {
  final List<Map<String, dynamic>> _rutinas = [
    {
      'titulo': 'Toma Segura de Medicamentos',
      'icono': '💊',
      'pasos': [
        'Lavarse las manos con agua y jabón',
        'Verificar el nombre y dosis de la medicina',
        'Ingerir el medicamento con abundante agua',
        'Registrar la toma en la aplicación',
      ],
    },
    {
      'titulo': 'Preparar una Infusión Relajante',
      'icono': '🍵',
      'pasos': [
        'Poner a calentar agua fresca en la olla',
        'Colocar la bolsita de manzanilla en la taza',
        'Verter el agua caliente y tapar 5 minutos',
        'Disfrutar con calma sin azúcar añadida',
      ],
    },
    {
      'titulo': 'Rutina Mañanera de Vitalidad',
      'icono': '🌅',
      'pasos': [
        'Despertar y estirar brazos y piernas en la cama',
        'Beber un vaso de agua a temperatura ambiente',
        'Desayunar alimentos con fibra y frutas',
        'Caminata suave de 15 minutos al sol',
      ],
    },
    {
      'titulo': 'Higiene y Buen Dormir',
      'icono': '🌙',
      'pasos': [
        'Cenar algo ligero 2 horas antes de acostarse',
        'Apagar el televisor y dispositivos móviles',
        'Cepillarse los dientes suavemente',
        'Acomodarse en la cama con respiración profunda',
      ],
    },
  ];

  int _rutinaActual = 0;
  List<String> _pasosMezclados = [];
  List<String> _pasosUsuario = [];
  int _puntajeAcumulado = 0;

  @override
  void initState() {
    super.initState();
    _cargarRutina();
  }

  void _cargarRutina() {
    final pasosOriginales = List<String>.from(_rutinas[_rutinaActual]['pasos']);
    final ordenados = List<String>.from(pasosOriginales);
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
    final pasosOriginales = List<String>.from(_rutinas[_rutinaActual]['pasos']);
    int aciertos = 0;

    for (int i = 0; i < _pasosUsuario.length; i++) {
      if (i < pasosOriginales.length &&
          _pasosUsuario[i] == pasosOriginales[i]) {
        aciertos++;
      }
    }

    final esPerfecto =
        _pasosUsuario.length == pasosOriginales.length &&
        aciertos == pasosOriginales.length;
    final puntos = esPerfecto ? 60 : (aciertos * 12);
    _puntajeAcumulado += puntos;

    if (_rutinaActual < _rutinas.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esPerfecto
                ? '✨ ¡Secuencia perfecta! +$puntos pts'
                : '👍 ¡Muy bien! Obtuviste +$puntos pts',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: esPerfecto ? AppColors.healthGreen : AppColors.primaryOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _rutinaActual++);
      _cargarRutina();
    } else {
      await ref.read(guardarPuntajeNotifierProvider).registrarPuntaje(
            tipoJuego: 'Ordenar Secuencia',
            puntaje: _puntajeAcumulado,
          );

      if (mounted) {
        VictoriaPuntajeDialog.mostrar(
          context: context,
          nombreJuego: 'Ordenar Secuencias',
          puntaje: _puntajeAcumulado,
          mensajePersonalizado:
              '¡Completaste todas las secuencias cotidianas! Organizar pasos lógicos ejercita las funciones ejecutivas del lóbulo frontal.',
          onJugarDeNuevo: () {
            setState(() {
              _rutinaActual = 0;
              _puntajeAcumulado = 0;
            });
            _cargarRutina();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rutina = _rutinas[_rutinaActual];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '🔢 Ordenar Secuencia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reiniciar rutina',
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: () {
              setState(() {
                _rutinaActual = 0;
                _puntajeAcumulado = 0;
              });
              _cargarRutina();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                              'Rutina ${_rutinaActual + 1} de ${_rutinas.length}',
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
                          backgroundColor: seleccionado
                              ? AppColors.primaryOrange
                              : Colors.grey.shade200,
                          foregroundColor:
                              seleccionado ? Colors.white : Colors.black87,
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
                  onPressed: _pasosUsuario.length == _pasosMezclados.length
                      ? _verificar
                      : null,
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
}
