import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';

class AddMetaDialog extends StatefulWidget {
  const AddMetaDialog({super.key});

  @override
  State<AddMetaDialog> createState() => _AddMetaDialogState();
}

class _AddMetaDialogState extends State<AddMetaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController(text: 'Tomar agua');
  int _objetivo = 8;
  String _unidad = 'vasos';
  String _iconoSeleccionado = '💧';

  final List<Map<String, dynamic>> _catalogoHabitos = [
    {
      'nombre': 'Tomar agua',
      'objetivo': 8,
      'unidad': 'vasos',
      'icono': '💧',
      'color': Color(0xFF0284C7),
      'descripcion': 'Mantén tu hidratación y vitalidad.',
    },
    {
      'nombre': 'Caminata y paseo',
      'objetivo': 30,
      'unidad': 'minutos',
      'icono': '🚶',
      'color': Color(0xFF059669),
      'descripcion': 'Activa tu corazón y articulaciones.',
    },
    {
      'nombre': 'Sol y Vitamina D',
      'objetivo': 15,
      'unidad': 'minutos',
      'icono': '☀️',
      'color': Color(0xFFD97706),
      'descripcion': 'Luz natural para tus huesos y ánimo.',
    },
    {
      'nombre': 'Estiramientos suaves',
      'objetivo': 10,
      'unidad': 'minutos',
      'icono': '🧘',
      'color': Color(0xFF4F46E5),
      'descripcion': 'Alivia tensiones de espalda y cuello.',
    },
    {
      'nombre': 'Sueño reparador',
      'objetivo': 8,
      'unidad': 'horas',
      'icono': '😴',
      'color': Color(0xFF6366F1),
      'descripcion': 'Descanso nocturno tranquilo.',
    },
    {
      'nombre': 'Fruta y verdura',
      'objetivo': 3,
      'unidad': 'porciones',
      'icono': '🥗',
      'color': Color(0xFF16A34A),
      'descripcion': 'Nutrición colorida y balanceada.',
    },
    {
      'nombre': 'Llamada familiar',
      'objetivo': 1,
      'unidad': 'charla',
      'icono': '📞',
      'color': Color(0xFFE11D48),
      'descripcion': 'Comparte alegría con tus seres queridos.',
    },
    {
      'nombre': 'Gimnasio mental',
      'objetivo': 15,
      'unidad': 'minutos',
      'icono': '🧠',
      'color': Color(0xFF9333EA),
      'descripcion': 'Sudoku, lectura o juegos de agilidad.',
    },
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _seleccionarHabito(Map<String, dynamic> habito) {
    HapticFeedback.selectionClick();
    setState(() {
      _nombreController.text = habito['nombre'] as String;
      _objetivo = habito['objetivo'] as int;
      _unidad = habito['unidad'] as String;
      _iconoSeleccionado = habito['icono'] as String;
    });
  }

  void _ajustarObjetivo(int delta) {
    HapticFeedback.lightImpact();
    setState(() {
      final nuevo = _objetivo + delta;
      if (nuevo >= 1 && nuevo <= 120) {
        _objetivo = nuevo;
      }
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop({
        'nombre': _nombreController.text.trim(),
        'objetivo': _objetivo,
        'progreso': 0,
        'unidad': _unidad.trim(),
        'icono': _iconoSeleccionado,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(_iconoSeleccionado, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Hábito de Bienestar',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            'Elige una sugerencia o personalízalo',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Sugerencias rápidas tipo chips accesibles
                const Text(
                  'Elige un hábito recomendado:',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _catalogoHabitos.map((habito) {
                    final esSeleccionado = _nombreController.text == habito['nombre'];
                    return InkWell(
                      onTap: () => _seleccionarHabito(habito),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: esSeleccionado ? AppColors.primaryTeal : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: esSeleccionado ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                            width: esSeleccionado ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(habito['icono'] as String, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              habito['nombre'] as String,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.w600,
                                color: esSeleccionado ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Nombre del hábito
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Hábito',
                    hintText: 'Ej. Paseo matutino',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Por favor escribe un nombre' : null,
                ),
                const SizedBox(height: 18),

                // Contador asistido de meta diaria
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Objetivo diario deseado:',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botón menos
                          InkWell(
                            onTap: () => _ajustarObjetivo(-1),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                              ),
                              child: const Icon(Icons.remove_rounded, color: AppColors.primaryTeal, size: 28),
                            ),
                          ),
                          // Cantidad central destacada
                          Column(
                            children: [
                              Text(
                                '$_objetivo',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                _unidad,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Botón más
                          InkWell(
                            onTap: () => _ajustarObjetivo(1),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Guardar Hábito',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
