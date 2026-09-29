import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../providers/medicamentos_provider.dart';

class AddTratamientoDialog extends ConsumerStatefulWidget {
  const AddTratamientoDialog({super.key});

  @override
  ConsumerState<AddTratamientoDialog> createState() => _AddTratamientoDialogState();
}

class _AddTratamientoDialogState extends ConsumerState<AddTratamientoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosticoController = TextEditingController();
  final _medicoController = TextEditingController();
  final _institucionController = TextEditingController();
  final _instruccionesController = TextEditingController();
  final _duracionDiasController = TextEditingController(text: '14');

  bool _esCronico = false;
  final Set<int> _selectedMedIds = {};

  final List<Map<String, dynamic>> _sugerenciasDiagnostico = const [
    {'nombre': 'Hipertensión Arterial', 'es_cronico': true, 'color': '#0D9488'},
    {'nombre': 'Diabetes Tipo 2', 'es_cronico': true, 'color': '#22C55E'},
    {'nombre': 'Control de Colesterol', 'es_cronico': true, 'color': '#818CF8'},
    {'nombre': 'Artrosis / Articular', 'es_cronico': true, 'color': '#F59E0B'},
    {'nombre': 'Infección (Antibiótico)', 'es_cronico': false, 'color': '#EC4899'},
  ];

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _medicoController.dispose();
    _institucionController.dispose();
    _instruccionesController.dispose();
    _duracionDiasController.dispose();
    super.dispose();
  }

  void _seleccionarSugerencia(Map<String, dynamic> sug) {
    setState(() {
      _diagnosticoController.text = sug['nombre'];
      _esCronico = sug['es_cronico'];
    });
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final fechaInicioStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      String? fechaFinStr;
      if (!_esCronico) {
        final dias = int.tryParse(_duracionDiasController.text.trim()) ?? 14;
        final fechaFin = now.add(Duration(days: dias));
        fechaFinStr = '${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}';
      }

      Navigator.of(context).pop({
        'diagnostico': _diagnosticoController.text.trim(),
        'medico_tratante': _medicoController.text.trim().isNotEmpty ? _medicoController.text.trim() : null,
        'institucion_salud': _institucionController.text.trim().isNotEmpty ? _institucionController.text.trim() : null,
        'instrucciones': _instruccionesController.text.trim().isNotEmpty ? _instruccionesController.text.trim() : null,
        'es_cronico': _esCronico,
        'fecha_inicio': fechaInicioStr,
        'fecha_fin': fechaFinStr,
        'medicamento_ids': _selectedMedIds.toList(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicamentos = ref.watch(medicamentosNotifierProvider).value ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.cardBackground,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Cabecera ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('📋', style: TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nuevo Tratamiento Médico',
                        style: AppTypography.titulo().copyWith(
                          fontSize: 21,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22, thickness: 1.5, color: AppColors.border),

                // ── Chips de Sugerencias ──
                const Text(
                  'Diagnósticos frecuentes:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _sugerenciasDiagnostico.map((sug) {
                    return ActionChip(
                      label: Text(sug['nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.4),
                      side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                      onPressed: () => _seleccionarSugerencia(sug),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Diagnóstico / Condición ──
                TextFormField(
                  controller: _diagnosticoController,
                  style: AppTypography.cuerpo(),
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico o Condición',
                    hintText: 'Ej: Hipertensión Arterial',
                    prefixIcon: Icon(Icons.healing_outlined, color: AppColors.primaryTeal),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el diagnóstico' : null,
                ),
                const SizedBox(height: 14),

                // ── Médico e Institución ──
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _medicoController,
                        style: AppTypography.cuerpo(),
                        decoration: const InputDecoration(
                          labelText: 'Médico tratante',
                          hintText: 'Ej: Dr. Gómez',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryTeal),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _institucionController,
                        style: AppTypography.cuerpo(),
                        decoration: const InputDecoration(
                          labelText: 'Clínica / EPS',
                          hintText: 'Ej: Sanitas',
                          prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.primaryTeal),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Switch de Crónico vs Temporal ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Es un tratamiento crónico / vitalicio?',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Ej: Hipertensión, diabetes, tiroides',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _esCronico,
                        activeThumbColor: AppColors.primaryTeal,
                        onChanged: (val) => setState(() => _esCronico = val),
                      ),
                    ],
                  ),
                ),

                // ── Duración en días si es temporal ──
                if (!_esCronico) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _duracionDiasController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.cuerpo(),
                    decoration: const InputDecoration(
                      labelText: 'Duración planificada (en días)',
                      hintText: 'Ej: 14',
                      prefixIcon: Icon(Icons.calendar_month_outlined, color: AppColors.primaryTeal),
                    ),
                    validator: (v) {
                      if (_esCronico) return null;
                      if (v == null || v.trim().isEmpty) return 'Indica los días';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Mínimo 1 día';
                      return null;
                    },
                  ),
                ],

                // ── Vincular Medicamentos Existentes ──
                if (medicamentos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona los medicamentos de este tratamiento:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: medicamentos.map((m) {
                      final idNum = int.tryParse(m.id.toString()) ?? 0;
                      final isSelected = _selectedMedIds.contains(idNum);
                      return FilterChip(
                        selected: isSelected,
                        label: Text('${m.nombre} (${m.miligramos ?? ""}mg)'),
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primaryTeal,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMedIds.add(idNum);
                            } else {
                              _selectedMedIds.remove(idNum);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Instrucciones o Cuidados ──
                TextFormField(
                  controller: _instruccionesController,
                  maxLines: 2,
                  style: AppTypography.cuerpo(),
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones médicas o cuidados asociados',
                    hintText: 'Ej: Tomar en ayunas, reducir consumo de sal',
                    prefixIcon: Icon(Icons.notes_outlined, color: AppColors.primaryTeal),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Botones ──
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
