import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../data/models/tratamiento_model.dart';
import '../../data/models/medicamento_model.dart';
import '../../data/repositories/medicamento_repository.dart';
import '../providers/medicamentos_provider.dart';

class AddTratamientoDialog extends ConsumerStatefulWidget {
  final TratamientoModel? tratamiento;

  const AddTratamientoDialog({super.key, this.tratamiento});

  @override
  ConsumerState<AddTratamientoDialog> createState() => _AddTratamientoDialogState();
}

class _AddTratamientoDialogState extends ConsumerState<AddTratamientoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _diagnosticoController;
  late final TextEditingController _especialidadController;
  late final TextEditingController _medicoController;
  late final TextEditingController _institucionController;
  late final TextEditingController _objetivoController;
  late final TextEditingController _recomendacionesController;
  late final TextEditingController _proximaCitaController;
  late final TextEditingController _instruccionesController;
  late final TextEditingController _duracionDiasController;

  late final TextEditingController _nuevoMedNombreController;
  late final TextEditingController _nuevoMedDosisController;
  bool _mostrarFormNuevoMed = false;
  bool _guardandoNuevoMed = false;

  late bool _esCronico;
  final Set<int> _selectedMedIds = {};

  final List<Map<String, dynamic>> _sugerenciasDiagnostico = const [
    {
      'nombre': 'Hipertensión Arterial',
      'especialidad': 'Cardiología',
      'es_cronico': true,
      'objetivo': 'Mantener TA < 130/80 mmHg',
      'recomendaciones': 'Dieta baja en sodio y caminata diaria.'
    },
    {
      'nombre': 'Diabetes Tipo 2',
      'especialidad': 'Endocrinología',
      'es_cronico': true,
      'objetivo': 'Glucemia ayunas < 100 mg/dL',
      'recomendaciones': 'Evitar azúcares simples y harinas refinadas.'
    },
    {
      'nombre': 'Artrosis / Dolor Articular',
      'especialidad': 'Reumatología',
      'es_cronico': true,
      'objetivo': 'Aliviar dolor y mantener movilidad articular',
      'recomendaciones': 'Fisioterapia y ejercicios de bajo impacto.'
    },
    {
      'nombre': 'Control de Colesterol',
      'especialidad': 'Medicina Interna',
      'es_cronico': true,
      'objetivo': 'LDL < 100 mg/dL',
      'recomendaciones': 'Aumentar consumo de fibra y agua.'
    },
    {
      'nombre': 'Infección (Antibiótico)',
      'especialidad': 'Medicina General',
      'es_cronico': false,
      'duracion': '7',
      'objetivo': 'Erradicación del cuadro infeccioso',
      'recomendaciones': 'Completar esquema sin suspender antes de tiempo.'
    },
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.tratamiento;
    _diagnosticoController = TextEditingController(text: t?.diagnostico ?? '');
    _especialidadController = TextEditingController(text: t?.especialidadMedica ?? 'Medicina General');
    _medicoController = TextEditingController(text: t?.medicoTratante ?? '');
    _institucionController = TextEditingController(text: t?.institucionSalud ?? '');
    _objetivoController = TextEditingController(text: t?.objetivoTerapeutico ?? '');
    _recomendacionesController = TextEditingController(text: t?.recomendaciones ?? '');
    _proximaCitaController = TextEditingController(text: t?.proximaCita ?? '');
    _instruccionesController = TextEditingController(text: t?.instrucciones ?? '');
    _duracionDiasController = TextEditingController(text: (t?.diasTotales != null && t!.diasTotales! > 0) ? t.diasTotales.toString() : '14');
    _nuevoMedNombreController = TextEditingController();
    _nuevoMedDosisController = TextEditingController();

    _esCronico = t?.esCronico ?? false;
    if (t != null && t.medicamentos.isNotEmpty) {
      for (final m in t.medicamentos) {
        final id = int.tryParse(m.id.toString());
        if (id != null && id > 0) _selectedMedIds.add(id);
      }
    }
  }

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _especialidadController.dispose();
    _medicoController.dispose();
    _institucionController.dispose();
    _objetivoController.dispose();
    _recomendacionesController.dispose();
    _proximaCitaController.dispose();
    _instruccionesController.dispose();
    _duracionDiasController.dispose();
    _nuevoMedNombreController.dispose();
    _nuevoMedDosisController.dispose();
    super.dispose();
  }

  void _seleccionarSugerencia(Map<String, dynamic> sug) {
    setState(() {
      _diagnosticoController.text = sug['nombre'];
      _especialidadController.text = sug['especialidad'];
      _esCronico = sug['es_cronico'];
      if (sug['objetivo'] != null) _objetivoController.text = sug['objetivo'];
      if (sug['recomendaciones'] != null) _recomendacionesController.text = sug['recomendaciones'];
      if (sug['duracion'] != null) _duracionDiasController.text = sug['duracion'];
    });
  }

  Future<void> _seleccionarFechaControl() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      helpText: 'SELECCIONAR FECHA DE PRÓXIMO CONTROL',
    );
    if (picked != null) {
      setState(() {
        _proximaCitaController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _crearYVincularMedicamento() async {
    final nombre = _nuevoMedNombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escribe el nombre del medicamento'),
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _guardandoNuevoMed = true);
    try {
      final rawDosis = _nuevoMedDosisController.text.trim();
      String? miligramos;
      if (rawDosis.isNotEmpty) {
        final cleaned = rawDosis.replaceAll(RegExp(r'(mg\s*)+', caseSensitive: false), 'mg').trim();
        miligramos = RegExp(r'^\d+(\.\d+)?$').hasMatch(cleaned) ? '$cleaned mg' : cleaned;
      }

      final nuevoMed = await ref.read(medicamentoRepositoryProvider).createMedicamento({
        'nombre': nombre,
        'miligramos': miligramos,
        'frecuencia': 24,
        'cantidad_restante': 30,
        'umbral_alerta': 5,
        'icono': '💊',
      });

      ref.invalidate(medicamentosNotifierProvider);

      final newId = int.tryParse(nuevoMed.id.toString());
      if (newId != null && newId > 0) {
        _selectedMedIds.add(newId);
      }

      _nuevoMedNombreController.clear();
      _nuevoMedDosisController.clear();

      setState(() {
        _mostrarFormNuevoMed = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Medicamento "$nombre" creado y seleccionado'),
            backgroundColor: AppColors.healthGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear medicamento: $e'),
            backgroundColor: AppColors.emergencyRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardandoNuevoMed = false);
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final fechaInicioStr = widget.tratamiento?.fechaInicio ??
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String? fechaFinStr;
      if (!_esCronico) {
        final dias = int.tryParse(_duracionDiasController.text.trim()) ?? 14;
        final fechaFin = now.add(Duration(days: dias));
        fechaFinStr =
            '${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}';
      }

      Navigator.of(context).pop({
        'diagnostico': _diagnosticoController.text.trim(),
        'especialidad_medica': _especialidadController.text.trim().isNotEmpty
            ? _especialidadController.text.trim()
            : 'Medicina General',
        'medico_tratante': _medicoController.text.trim().isNotEmpty ? _medicoController.text.trim() : null,
        'institucion_salud': _institucionController.text.trim().isNotEmpty ? _institucionController.text.trim() : null,
        'objetivo_terapeutico': _objetivoController.text.trim().isNotEmpty ? _objetivoController.text.trim() : null,
        'recomendaciones': _recomendacionesController.text.trim().isNotEmpty ? _recomendacionesController.text.trim() : null,
        'proxima_cita': _proximaCitaController.text.trim().isNotEmpty ? _proximaCitaController.text.trim() : null,
        'instrucciones': _instruccionesController.text.trim().isNotEmpty ? _instruccionesController.text.trim() : null,
        'es_cronico': _esCronico,
        'fecha_inicio': fechaInicioStr,
        'fecha_fin': fechaFinStr,
        'medicamento_ids': _selectedMedIds.where((id) => id > 0).toList(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicamentos = ref.watch(medicamentosNotifierProvider).value ?? [];
    final esEdicion = widget.tratamiento != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(esEdicion ? '✏️' : '📋', style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        esEdicion ? 'Editar Tratamiento Clínico' : 'Nuevo Tratamiento Clínico',
                        style: AppTypography.titulo().copyWith(
                          fontSize: 22,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1.5, color: AppColors.border),

                // ── Chips de Sugerencias Ergonómicas (52dp) ──
                if (!esEdicion) ...[
                  const Text(
                    'Plantillas de diagnóstico frecuente:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sugerenciasDiagnostico.map((sug) {
                      return InkWell(
                        onTap: () => _seleccionarSugerencia(sug),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryTeal),
                              const SizedBox(width: 6),
                              Text(
                                sug['nombre'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],

                // ── Diagnóstico / Condición ──
                TextFormField(
                  controller: _diagnosticoController,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico o Condición Médica',
                    labelStyle: TextStyle(fontSize: 16),
                    hintText: 'Ej: Hipertensión Arterial',
                    prefixIcon: Icon(Icons.healing_outlined, color: AppColors.primaryTeal, size: 24),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el diagnóstico médico' : null,
                ),
                const SizedBox(height: 14),

                // ── Especialidad Médica ──
                TextFormField(
                  controller: _especialidadController,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Especialidad Médica',
                    labelStyle: TextStyle(fontSize: 16),
                    hintText: 'Ej: Geriatría, Cardiología, Reumatología',
                    prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.primaryTeal, size: 24),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Médico e Institución ──
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _medicoController,
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Médico tratante',
                          labelStyle: TextStyle(fontSize: 16),
                          hintText: 'Dr. / Dra.',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryTeal, size: 24),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _institucionController,
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Clínica / Entidad',
                          labelStyle: TextStyle(fontSize: 16),
                          hintText: 'Ej: SURA, Sanitas',
                          prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.primaryTeal, size: 24),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Switch de Crónico vs Temporal ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
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
                              '¿Tratamiento Permanente o Crónico?',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ej: Hipertensión, diabetes, hipotiroidismo',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _duracionDiasController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Duración total planificada (en días)',
                      labelStyle: TextStyle(fontSize: 16),
                      hintText: 'Ej: 14',
                      prefixIcon: Icon(Icons.calendar_month_outlined, color: AppColors.primaryTeal, size: 24),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    validator: (v) {
                      if (_esCronico) return null;
                      if (v == null || v.trim().isEmpty) return 'Indica los días de duración';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Mínimo 1 día';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),

                // ── Objetivo Terapéutico ──
                TextFormField(
                  controller: _objetivoController,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Objetivo Terapéutico / Meta de Salud',
                    labelStyle: TextStyle(fontSize: 16),
                    hintText: 'Ej: Mantener presión < 130/80 mmHg',
                    prefixIcon: Icon(Icons.track_changes_outlined, color: AppColors.primaryTeal, size: 24),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Recomendaciones no farmacológicas ──
                TextFormField(
                  controller: _recomendacionesController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Recomendaciones y Dieta no farmacológica',
                    labelStyle: TextStyle(fontSize: 16),
                    hintText: 'Ej: Reducir consumo de sal, caminata 20 min al día',
                    prefixIcon: Icon(Icons.eco_outlined, color: AppColors.primaryTeal, size: 24),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Próximo Control Médico ──
                TextFormField(
                  controller: _proximaCitaController,
                  readOnly: true,
                  onTap: _seleccionarFechaControl,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Próxima Cita de Control',
                    labelStyle: const TextStyle(fontSize: 16),
                    hintText: 'Seleccionar fecha en calendario',
                    prefixIcon: const Icon(Icons.event, color: AppColors.primaryTeal, size: 24),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, color: AppColors.primaryTeal),
                      onPressed: _seleccionarFechaControl,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Vincular o Crear Medicamentos ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Medicamentos asociados:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _mostrarFormNuevoMed = !_mostrarFormNuevoMed;
                        });
                      },
                      icon: Icon(
                        _mostrarFormNuevoMed ? Icons.close_rounded : Icons.add_circle_outline_rounded,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                      label: Text(
                        _mostrarFormNuevoMed ? 'Cerrar' : '+ Escribir nuevo',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Formulario rápido para crear y asociar un nuevo medicamento
                if (_mostrarFormNuevoMed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Escribe los datos del medicamento para asociarlo:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nuevoMedNombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del medicamento',
                            hintText: 'Ej: Amlodipino',
                            prefixIcon: Icon(Icons.medication_rounded, color: AppColors.primaryTeal, size: 22),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nuevoMedDosisController,
                          decoration: const InputDecoration(
                            labelText: 'Dosis o Gramaje (opcional)',
                            hintText: 'Ej: 5 mg',
                            prefixIcon: Icon(Icons.scale_rounded, color: AppColors.primaryTeal, size: 22),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _guardandoNuevoMed
                                  ? null
                                  : () => setState(() => _mostrarFormNuevoMed = false),
                              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _guardandoNuevoMed ? null : _crearYVincularMedicamento,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _guardandoNuevoMed
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: const Text(
                                'Guardar y Asociar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Lista de chips de medicamentos existentes o mensaje de vacío
                if (medicamentos.isEmpty && !_mostrarFormNuevoMed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'No tienes medicamentos registrados. Pulsa "+ Escribir nuevo" para agregar el primero a este tratamiento.',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (medicamentos.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: medicamentos.map((m) {
                      final idNum = int.tryParse(m.id.toString()) ?? 0;
                      final isSelected = _selectedMedIds.contains(idNum);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(
                          m.nombreConDosis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const SizedBox(height: 14),
                ],

                // ── Instrucciones o Cuidados ──
                TextFormField(
                  controller: _instruccionesController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones adicionales o posología',
                    labelStyle: TextStyle(fontSize: 16),
                    hintText: 'Ej: Tomar en ayunas con vaso completo de agua',
                    prefixIcon: Icon(Icons.notes_outlined, color: AppColors.primaryTeal, size: 24),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Botones de Guardar / Cancelar (54dp) ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 17, color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                        ),
                        child: Text(
                          esEdicion ? 'Actualizar' : 'Guardar',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
