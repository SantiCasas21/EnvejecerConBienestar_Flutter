import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../providers/tratamientos_provider.dart';

class AddMedicamentoDialog extends ConsumerStatefulWidget {
  const AddMedicamentoDialog({super.key});

  @override
  ConsumerState<AddMedicamentoDialog> createState() => _AddMedicamentoDialogState();
}

class _AddMedicamentoDialogState extends ConsumerState<AddMedicamentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dosisController = TextEditingController();
  final _frecuenciaController = TextEditingController(text: '8');
  final _cantidadController = TextEditingController(text: '30');
  final _notasController = TextEditingController();
  TimeOfDay _horaAlarma = const TimeOfDay(hour: 8, minute: 0);
  int? _tratamientoId;

  final List<Map<String, String>> _sugerencias = const [
    {'nombre': 'Losartán', 'dosis': '50', 'frecuencia': '12', 'icono': '💊', 'notas': 'Presión arterial'},
    {'nombre': 'Metformina', 'dosis': '850', 'frecuencia': '24', 'icono': '💊', 'notas': 'Con el desayuno'},
    {'nombre': 'Omeprazol', 'dosis': '20', 'frecuencia': '24', 'icono': '💊', 'notas': 'En ayunas'},
    {'nombre': 'Acetaminofén', 'dosis': '500', 'frecuencia': '8', 'icono': '💊', 'notas': 'Dolor leve'},
    {'nombre': 'Atorvastatina', 'dosis': '20', 'frecuencia': '24', 'icono': '💊', 'notas': 'En la noche'},
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _dosisController.dispose();
    _frecuenciaController.dispose();
    _cantidadController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _seleccionarSugerencia(Map<String, String> sug) {
    setState(() {
      _nombreController.text = sug['nombre']!;
      _dosisController.text = sug['dosis']!;
      _frecuenciaController.text = sug['frecuencia']!;
      _notasController.text = sug['notas'] ?? '';
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final horaStr = '${_horaAlarma.hour.toString().padLeft(2, '0')}:${_horaAlarma.minute.toString().padLeft(2, '0')}:00';
      Navigator.of(context).pop({
        'nombre': _nombreController.text.trim(),
        'miligramos': _dosisController.text.trim(),
        'frecuencia': int.tryParse(_frecuenciaController.text.trim()) ?? 8,
        'cantidad_restante': int.tryParse(_cantidadController.text.trim()) ?? 30,
        'hora_alarma': horaStr,
        'notas': _notasController.text.trim(),
        'icono': '💊',
        'tratamiento_id': _tratamientoId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tratamientos = ref.watch(tratamientosNotifierProvider).value ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.cardBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('💊', style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Agregar Medicamento',
                        style: AppTypography.titulo().copyWith(
                          fontSize: 21,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 1.5, color: AppColors.border),

                // Sugerencias rápidas
                const Text(
                  'Sugerencias rápidas (toca para autorrellenar):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _sugerencias.map((sug) {
                    return ActionChip(
                      avatar: Text(sug['icono']!),
                      label: Text('${sug['nombre']} ${sug['dosis']}mg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.4),
                      side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.4)),
                      onPressed: () => _seleccionarSugerencia(sug),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selector de Tratamiento de Ficha Médica
                if (tratamientos.isNotEmpty) ...[
                  DropdownButtonFormField<int?>(
                    initialValue: _tratamientoId,
                    isExpanded: true,
                    style: AppTypography.cuerpo(),
                    decoration: const InputDecoration(
                      labelText: 'Vincular a Tratamiento de tu Perfil',
                      hintText: 'Opcional: Selecciona un tratamiento',
                      prefixIcon: Icon(Icons.assignment_outlined, color: AppColors.primaryTeal),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Ninguno (Medicamento independiente)'),
                      ),
                      ...tratamientos.map((t) {
                        final idInt = t.id is int ? t.id as int : int.tryParse(t.id.toString());
                        return DropdownMenuItem<int?>(
                          value: idInt,
                          child: Text(
                            '${t.diagnostico} ${t.medicoTratante != null ? "(${t.medicoTratante})" : ""}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _tratamientoId = val),
                  ),
                  const SizedBox(height: 14),
                ],

                // Nombre
                TextFormField(
                  controller: _nombreController,
                  style: AppTypography.cuerpo(),
                  decoration: const InputDecoration(
                    labelText: 'Nombre del medicamento',
                    hintText: 'Ej: Losartán Potásico',
                    prefixIcon: Icon(Icons.medication_outlined, color: AppColors.primaryTeal),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del medicamento' : null,
                ),
                const SizedBox(height: 12),

                // Dosis y Frecuencia
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dosisController,
                        style: AppTypography.cuerpo(),
                        decoration: const InputDecoration(
                          labelText: 'Dosis (mg)',
                          hintText: 'Ej: 50',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _frecuenciaController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.cuerpo(),
                        decoration: const InputDecoration(
                          labelText: 'Cada cuántas horas',
                          hintText: 'Ej: 8',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1 || n > 72) return 'Entre 1 y 72h';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stock en caja y Hora de primera alarma
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.cuerpo(),
                        decoration: const InputDecoration(
                          labelText: 'Pastillas en caja',
                          hintText: 'Ej: 30',
                          prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.primaryTeal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.alarm_rounded, color: AppColors.primaryTeal),
                        label: Text(
                          '${_horaAlarma.hour.toString().padLeft(2, '0')}:${_horaAlarma.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primaryTeal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _horaAlarma);
                          if (picked != null) setState(() => _horaAlarma = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notas
                TextFormField(
                  controller: _notasController,
                  maxLines: 2,
                  style: AppTypography.cuerpo(),
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones o notas (ej: con alimentos)',
                    prefixIcon: Icon(Icons.note_alt_outlined, color: AppColors.primaryTeal),
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Guardar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
