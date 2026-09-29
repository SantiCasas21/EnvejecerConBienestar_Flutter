import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

class AddMetaDialog extends StatefulWidget {
  const AddMetaDialog({super.key});

  @override
  State<AddMetaDialog> createState() => _AddMetaDialogState();
}

class _AddMetaDialogState extends State<AddMetaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _objetivoController = TextEditingController(text: '8');
  final _unidadController = TextEditingController(text: 'vasos');

  final List<Map<String, String>> _sugerencias = [
    {'nombre': 'Tomar agua', 'objetivo': '8', 'unidad': 'vasos', 'icono': '💧'},
    {'nombre': 'Caminata diaria', 'objetivo': '30', 'unidad': 'minutos', 'icono': '🚶‍♂️'},
    {'nombre': 'Ejercicio de memoria', 'objetivo': '15', 'unidad': 'minutos', 'icono': '🧠'},
    {'nombre': 'Sueño reparador', 'objetivo': '8', 'unidad': 'horas', 'icono': '😴'},
    {'nombre': 'Lectura de libro', 'objetivo': '20', 'unidad': 'páginas', 'icono': '📖'},
  ];

  String _iconoSeleccionado = '🎯';

  void _seleccionarSugerencia(Map<String, String> sug) {
    setState(() {
      _nombreController.text = sug['nombre']!;
      _objetivoController.text = sug['objetivo']!;
      _unidadController.text = sug['unidad']!;
      _iconoSeleccionado = sug['icono']!;
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'nombre': _nombreController.text.trim(),
        'objetivo': int.tryParse(_objetivoController.text) ?? 1,
        'progreso': 0,
        'unidad': _unidadController.text.trim(),
        'icono': _iconoSeleccionado,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$_iconoSeleccionado Nueva Meta de Salud',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 16),
              const Text('Sugerencias rápidas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sugerencias.map((sug) {
                  return ChoiceChip(
                    avatar: Text(sug['icono']!),
                    label: Text(sug['nombre']!),
                    selected: _nombreController.text == sug['nombre'],
                    onSelected: (_) => _seleccionarSugerencia(sug),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Nombre de la meta',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _objetivoController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Objetivo diario',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el número' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unidadController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Unidad (vasos, min, etc.)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Crear Meta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
