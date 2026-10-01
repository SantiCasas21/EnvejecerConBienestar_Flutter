import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../medicamentos/presentation/providers/tratamientos_provider.dart';
import '../../../medicamentos/presentation/widgets/add_tratamiento_dialog.dart';
import '../../../medicamentos/presentation/widgets/tratamiento_card.dart';
import '../providers/perfil_provider.dart';
import '../../data/models/perfil_model.dart';
import '../widgets/habeas_data_dialog.dart';
import '../widgets/imc_info_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _fechaNacimiento;
  final _edadController = TextEditingController();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _epsController = TextEditingController();
  final _telefonoPropioController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _condicionesController = TextEditingController();
  final _cirugiasController = TextEditingController();
  final _dispositivosController = TextEditingController();
  
  final _contactoEmergenciaNombreController = TextEditingController();
  final _contactoEmergenciaTelefonoController = TextEditingController();
  String _contactoEmergenciaParentesco = 'Hijo / Hija';
  
  final _medicoTratanteController = TextEditingController();
  final _telefonoMedicoController = TextEditingController();
  final _clinicaPreferidaController = TextEditingController();
  final _notasAdicionalesController = TextEditingController();

  String _tipoSangre = 'O+';
  String _genero = 'Femenino';
  String _tipoDocumento = 'CC';
  final _numeroDocumentoController = TextEditingController();
  String _regimenEps = 'Contributivo';
  final _presionHabitualController = TextEditingController();
  String _nivelMovilidad = 'Independiente';
  final _restriccionesAlimentariasController = TextEditingController();
  final _antecedentesFamiliaresController = TextEditingController();

  bool _datosCargados = false;
  bool _guardando = false;
  bool _aceptoHabeasData = false;

  final List<String> _tiposSangre = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  final List<String> _generos = ['Femenino', 'Masculino', 'No especificado', 'Otro'];
  final List<String> _tiposDocumento = ['CC', 'CE', 'TI', 'PAS', 'PEP'];
  final List<String> _regimenesEps = ['Contributivo', 'Subsidiado', 'Especial / Magisterio', 'Particular', 'Otro'];
  final List<String> _nivelesMovilidad = [
    'Independiente',
    'Bastón o Andador',
    'Silla de Ruedas',
    'Asistencia Total / Encamado',
  ];
  
  // Lista ampliada y completa de parentescos y redes de apoyo
  final List<String> _parentescos = [
    'Hijo / Hija',
    'Cónyuge / Pareja',
    'Hermano / Hermana',
    'Padre / Madre',
    'Nieto / Nieta',
    'Sobrino / Sobrina',
    'Primo / Prima',
    'Yerno / Nuera',
    'Suegro / Suegra',
    'Cuidador / Cuidadora',
    'Enfermero / Enfermera',
    'Médico de confianza',
    'Vecino / Vecina',
    'Amigo / Amiga cercano(a)',
    'Familiar',
    'Tutor Legal / Apoderado',
    'Otro contacto',
  ];

  @override
  void initState() {
    super.initState();
    final perfil = ref.read(perfilNotifierProvider).value;
    if (perfil != null) {
      _llenarFormulario(perfil);
    }
  }

  @override
  void dispose() {
    _edadController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _epsController.dispose();
    _telefonoPropioController.dispose();
    _alergiasController.dispose();
    _condicionesController.dispose();
    _cirugiasController.dispose();
    _dispositivosController.dispose();
    _contactoEmergenciaNombreController.dispose();
    _contactoEmergenciaTelefonoController.dispose();
    _medicoTratanteController.dispose();
    _telefonoMedicoController.dispose();
    _clinicaPreferidaController.dispose();
    _notasAdicionalesController.dispose();
    _numeroDocumentoController.dispose();
    _presionHabitualController.dispose();
    _restriccionesAlimentariasController.dispose();
    _antecedentesFamiliaresController.dispose();
    super.dispose();
  }

  void _llenarFormulario(dynamic perfil) {
    if (perfil == null) return;
    if (perfil.fechaNacimiento != null && (perfil.fechaNacimiento as String).isNotEmpty) {
      try {
        _fechaNacimiento = DateTime.parse(perfil.fechaNacimiento as String);
      } catch (_) {}
    }
    _edadController.text = perfil.edad != null ? perfil.edad.toString() : '';
    _pesoController.text = perfil.peso != null ? perfil.peso.toString() : '';
    _alturaController.text = perfil.altura != null ? perfil.altura.toString() : '';
    _epsController.text = (perfil.eps != null && perfil.eps != 'No especificada') ? perfil.eps : '';
    _telefonoPropioController.text = perfil.telefono ?? '';
    _alergiasController.text = (perfil.alergias != null && perfil.alergias != 'Ninguna') ? perfil.alergias : '';
    _condicionesController.text = (perfil.condiciones != null && perfil.condiciones != 'Ninguna') ? perfil.condiciones : '';
    _cirugiasController.text = (perfil.cirugias != null && perfil.cirugias != 'Ninguna') ? perfil.cirugias : '';
    _dispositivosController.text = (perfil.dispositivosMedicos != null && perfil.dispositivosMedicos != 'Ninguno') ? perfil.dispositivosMedicos : '';
    
    _contactoEmergenciaNombreController.text = perfil.contactoEmergenciaNombre ?? '';
    _contactoEmergenciaTelefonoController.text = perfil.contactoEmergenciaTelefono ?? '';
    if (perfil.contactoEmergenciaParentesco != null && (perfil.contactoEmergenciaParentesco as String).isNotEmpty) {
      final parentesco = perfil.contactoEmergenciaParentesco as String;
      if (!_parentescos.contains(parentesco)) {
        _parentescos.insert(0, parentesco);
      }
      _contactoEmergenciaParentesco = parentesco;
    }

    _medicoTratanteController.text = perfil.medicoTratante ?? '';
    _telefonoMedicoController.text = perfil.telefonoMedico ?? '';
    _clinicaPreferidaController.text = (perfil.clinicaPreferida != null && perfil.clinicaPreferida != 'Hospital General') ? perfil.clinicaPreferida : '';
    _notasAdicionalesController.text = perfil.notasAdicionales ?? '';

    if (perfil.tipoSangre != null && _tiposSangre.contains(perfil.tipoSangre)) {
      _tipoSangre = perfil.tipoSangre!;
    }
    if (perfil.genero != null && (perfil.genero as String).isNotEmpty) {
      final gen = perfil.genero as String;
      if (!_generos.contains(gen)) {
        _generos.insert(0, gen);
      }
      _genero = gen;
    }

    if (perfil.tipoDocumento != null && _tiposDocumento.contains(perfil.tipoDocumento)) {
      _tipoDocumento = perfil.tipoDocumento!;
    }
    _numeroDocumentoController.text = perfil.numeroDocumento ?? '';
    if (perfil.regimenEps != null && _regimenesEps.contains(perfil.regimenEps)) {
      _regimenEps = perfil.regimenEps!;
    }
    _presionHabitualController.text = perfil.presionHabitual ?? '';
    if (perfil.nivelMovilidad != null && _nivelesMovilidad.contains(perfil.nivelMovilidad)) {
      _nivelMovilidad = perfil.nivelMovilidad!;
    }
    _restriccionesAlimentariasController.text = perfil.restriccionesAlimentarias ?? '';
    _antecedentesFamiliaresController.text = perfil.antecedentesFamiliares ?? '';

    _aceptoHabeasData = perfil.aceptoHabeasData ?? false;
    _datosCargados = true;
  }

  void _abrirAddTratamiento() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddTratamientoDialog(),
    );

    if (result != null) {
      try {
        await ref.read(tratamientosNotifierProvider.notifier).addTratamiento(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Tratamiento para ${result['diagnostico']} registrado exitosamente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.healthGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al guardar tratamiento: $e', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.emergencyRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  String _formatearFechaNacimientoTexto(DateTime? fecha) {
    if (fecha == null) return 'Toca aquí para seleccionar fecha';
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final mesNombre = meses[fecha.month - 1];
    final now = DateTime.now();
    final edad = now.year - fecha.year -
        ((now.month < fecha.month || (now.month == fecha.month && now.day < fecha.day)) ? 1 : 0);
    final mesCapitalizado = '${mesNombre[0].toUpperCase()}${mesNombre.substring(1)}';
    return '${fecha.day} de $mesCapitalizado de ${fecha.year} ($edad años)';
  }

  void _seleccionarFechaNacimiento() async {
    final now = DateTime.now();
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 70, now.month, now.day),
      firstDate: DateTime(1910),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Selecciona tu Año y Fecha de Nacimiento',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaNacimiento = fechaSeleccionada;
        final edadCalculada = now.year - fechaSeleccionada.year - 
            ((now.month < fechaSeleccionada.month || (now.month == fechaSeleccionada.month && now.day < fechaSeleccionada.day)) ? 1 : 0);
        _edadController.text = edadCalculada.toString();
      });
    }
  }

  double? _calcularImcEnVivo() {
    final p = double.tryParse(_pesoController.text.trim().replaceAll(',', '.'));
    final a = double.tryParse(_alturaController.text.trim().replaceAll(',', '.'));
    if (p != null && a != null && a >= 50 && a <= 250 && p >= 20 && p <= 300) {
      final aMetros = a / 100.0;
      return p / (aMetros * aMetros);
    }
    return null;
  }

  String _clasificacionImcEnVivo(double imc) {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25.0) return 'Peso saludable';
    if (imc < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _colorImcEnVivo(double imc) {
    if (imc >= 18.5 && imc < 25.0) return const Color(0xFF22C55E);
    if (imc < 18.5 || (imc >= 25.0 && imc < 30.0)) return const Color(0xFFF97316);
    return const Color(0xFFE11D48);
  }

  String? _validarTelefonoColombia(String? val, {bool obligatorio = false}) {
    if (val == null || val.trim().isEmpty) {
      if (obligatorio) return 'El teléfono es obligatorio';
      return null;
    }
    final digitos = val.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 10) {
      return 'Debe tener mínimo 10 dígitos (ej: 3001234567)';
    }
    return null;
  }

  void _guardarFichaMedica() async {
    if (_formKey.currentState!.validate()) {
      if (!_aceptoHabeasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚠️ Debes aceptar la autorización de Habeas Data (Ley 1581 de 2012) para proteger tus datos de salud.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.emergencyRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      setState(() => _guardando = true);

      final fechaStr = _fechaNacimiento != null 
          ? '${_fechaNacimiento!.year.toString().padLeft(4, '0')}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}'
          : null;

      final data = {
        'fecha_nacimiento': fechaStr,
        'edad': int.tryParse(_edadController.text.trim()),
        'genero': _genero,
        'tipo_sangre': _tipoSangre,
        'peso': double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
        'altura': double.tryParse(_alturaController.text.trim().replaceAll(',', '.')),
        'eps': _epsController.text.trim().isEmpty ? 'No especificada' : _epsController.text.trim(),
        'telefono': _telefonoPropioController.text.trim(),
        'alergias': _alergiasController.text.trim().isEmpty ? 'Ninguna' : _alergiasController.text.trim(),
        'condiciones': _condicionesController.text.trim().isEmpty ? 'Ninguna' : _condicionesController.text.trim(),
        'cirugias': _cirugiasController.text.trim().isEmpty ? 'Ninguna' : _cirugiasController.text.trim(),
        'dispositivos_medicos': _dispositivosController.text.trim().isEmpty ? 'Ninguno' : _dispositivosController.text.trim(),
        'contacto_emergencia_nombre': _contactoEmergenciaNombreController.text.trim(),
        'contacto_emergencia_telefono': _contactoEmergenciaTelefonoController.text.trim(),
        'contacto_emergencia_parentesco': _contactoEmergenciaParentesco,
        'medico_tratante': _medicoTratanteController.text.trim(),
        'telefono_medico': _telefonoMedicoController.text.trim(),
        'clinica_preferida': _clinicaPreferidaController.text.trim().isEmpty ? 'Hospital General' : _clinicaPreferidaController.text.trim(),
        'notas_adicionales': _notasAdicionalesController.text.trim(),
        'tipo_documento': _tipoDocumento,
        'numero_documento': _numeroDocumentoController.text.trim(),
        'regimen_eps': _regimenEps,
        'presion_habitual': _presionHabitualController.text.trim(),
        'nivel_movilidad': _nivelMovilidad,
        'restricciones_alimentarias': _restriccionesAlimentariasController.text.trim(),
        'antecedentes_familiares': _antecedentesFamiliaresController.text.trim(),
        'acepto_habeas_data': _aceptoHabeasData,
      };

      try {
        await ref.read(perfilNotifierProvider.notifier).guardarPerfil(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '✅ Ficha médica guardada exitosamente',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.healthGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: AppColors.emergencyRed,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PerfilModel?>>(perfilNotifierProvider, (prev, next) {
      final perfil = next.value;
      if (perfil != null && !_datosCargados) {
        setState(() {
          _llenarFormulario(perfil);
        });
      }
    });

    final perfilAsync = ref.watch(perfilNotifierProvider);
    if (!_datosCargados && perfilAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Ficha Médica',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 30, color: AppColors.primaryTeal),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }

    if (perfilAsync.value != null && !_datosCargados) {
      _llenarFormulario(perfilAsync.value!);
    }

    final imcEnVivo = _calcularImcEnVivo();
    final authUser = ref.watch(authNotifierProvider).user;
    final userEmail = authUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Completar Ficha Médica',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30, color: AppColors.primaryTeal),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── SECCIÓN 1: DATOS VITALES Y CUMPLEAÑOS ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '1. Datos Vitales e Identidad',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.5, color: AppColors.border),

                        // Correo Electrónico (No editable - Identificador de cuenta)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, color: AppColors.primaryTeal, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Correo de la cuenta',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      userEmail.isNotEmpty ? userEmail : 'No registrado',
                                      style: AppTypography.cuerpo().copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                                    SizedBox(width: 4),
                                    Text(
                                      'No editable',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tipo y Número de Documento de Identidad
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: DropdownButtonFormField<String>(
                                initialValue: _tipoDocumento,
                                isExpanded: true,
                                items: _tiposDocumento.map((td) => DropdownMenuItem(value: td, child: Text(td, style: AppTypography.cuerpo()))).toList(),
                                onChanged: (val) => setState(() => _tipoDocumento = val ?? 'CC'),
                                decoration: const InputDecoration(labelText: 'Tipo Doc'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 7,
                              child: TextFormField(
                                controller: _numeroDocumentoController,
                                keyboardType: TextInputType.text,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Número de Documento',
                                  hintText: 'Ej: 19458291',
                                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryTeal),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Fecha de Nacimiento con DatePicker
                        InkWell(
                          onTap: _seleccionarFechaNacimiento,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined, color: AppColors.primaryTeal, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Fecha de Nacimiento / Cumpleaños',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatearFechaNacimientoTexto(_fechaNacimiento),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _fechaNacimiento != null ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.calendar_month_rounded, color: AppColors.primaryTeal),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Edad y Tipo de Sangre con validadores
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _edadController,
                                keyboardType: TextInputType.number,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Edad (años)',
                                  hintText: 'Ej: 75',
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final num = int.tryParse(val.trim());
                                    if (num == null || num < 0 || num > 120) {
                                      return 'Edad entre 0 y 120';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                initialValue: _tipoSangre,
                                isExpanded: true,
                                items: _tiposSangre.map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.cuerpo()))).toList(),
                                onChanged: (val) => setState(() => _tipoSangre = val ?? 'O+'),
                                decoration: const InputDecoration(
                                  labelText: 'Tipo Sangre',
                                  prefixIcon: Icon(Icons.bloodtype_outlined, color: AppColors.emergencyRed),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Género y Teléfono propio con validación
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                initialValue: _genero,
                                isExpanded: true,
                                items: _generos.map((g) => DropdownMenuItem(value: g, child: Text(g, style: AppTypography.cuerpo()))).toList(),
                                onChanged: (val) => setState(() => _genero = val ?? 'Femenino'),
                                decoration: const InputDecoration(labelText: 'Género'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _telefonoPropioController,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono Propio (10 dígitos)',
                                  hintText: 'Ej: 3101234567 o 6013456789',
                                ),
                                validator: (val) => _validarTelefonoColombia(val, obligatorio: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── SECCIÓN 2: BIOMETRÍA E IMC CON EXPLICACIÓN INTERACTIVA ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Text('⚖️', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '2. Biometría y Peso',
                                      style: AppTypography.subtitulo().copyWith(
                                        color: AppColors.primaryTeal,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => ImcInfoDialog.mostrar(context),
                              icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.primaryTeal),
                              label: const Text('¿Qué es IMC?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                            ),
                          ],
                        ),
                        const Divider(height: 16, thickness: 1.5, color: AppColors.border),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _pesoController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Peso (kg)',
                                  hintText: 'Ej: 68.5',
                                  prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.primaryTeal),
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final p = double.tryParse(val.trim().replaceAll(',', '.'));
                                    if (p == null || p < 20 || p > 300) {
                                      return 'Peso entre 20 y 300 kg';
                                    }
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _alturaController,
                                keyboardType: TextInputType.number,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Altura (cm)',
                                  hintText: 'Ej: 165',
                                  prefixIcon: Icon(Icons.height_outlined, color: AppColors.primaryTeal),
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final a = double.tryParse(val.trim().replaceAll(',', '.'));
                                    if (a == null || a < 50 || a > 250) {
                                      return 'Altura entre 50 y 250 cm';
                                    }
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        // Previsualización interactiva de IMC en tiempo real
                        if (imcEnVivo != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _colorImcEnVivo(imcEnVivo).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _colorImcEnVivo(imcEnVivo), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.accessibility_new_rounded, color: _colorImcEnVivo(imcEnVivo), size: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'IMC Calculado: ${imcEnVivo.toStringAsFixed(1)} kg/m²',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _colorImcEnVivo(imcEnVivo),
                                        ),
                                      ),
                                      Text(
                                        'Clasificación: ${_clasificacionImcEnVivo(imcEnVivo)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _presionHabitualController,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Presión Habitual',
                                  hintText: 'Ej: 120/80 mmHg',
                                  prefixIcon: Icon(Icons.monitor_heart_outlined, color: AppColors.emergencyRed),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: DropdownButtonFormField<String>(
                                initialValue: _nivelMovilidad,
                                isExpanded: true,
                                items: _nivelesMovilidad.map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m, style: const TextStyle(fontSize: 14)),
                                )).toList(),
                                onChanged: (val) => setState(() => _nivelMovilidad = val ?? 'Independiente'),
                                decoration: const InputDecoration(
                                  labelText: 'Movilidad',
                                  prefixIcon: Icon(Icons.directions_walk_rounded, color: AppColors.primaryTeal),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── SECCIÓN 3: CONTACTO DE EMERGENCIA SOS (CON PARENTESCO AMPLIADO) ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🆘', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '3. Contacto de Emergencia SOS',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.emergencyRed,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.5, color: AppColors.border),

                        TextFormField(
                          controller: _contactoEmergenciaNombreController,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Familiar / Contacto SOS',
                            hintText: 'Ej: Carolina Gómez',
                            prefixIcon: Icon(Icons.person_pin_circle_outlined, color: AppColors.emergencyRed),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _contactoEmergenciaTelefonoController,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono de Urgencias (10 dígitos)',
                                  hintText: 'Ej: 3001234567',
                                  prefixIcon: Icon(Icons.phone_in_talk_outlined, color: AppColors.emergencyRed),
                                ),
                                validator: (val) => _validarTelefonoColombia(val, obligatorio: false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 6,
                              child: DropdownButtonFormField<String>(
                                initialValue: _contactoEmergenciaParentesco,
                                isExpanded: true,
                                items: _parentescos.map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p, style: const TextStyle(fontSize: 14)),
                                )).toList(),
                                onChanged: (val) => setState(() => _contactoEmergenciaParentesco = val ?? 'Hijo / Hija'),
                                decoration: const InputDecoration(
                                  labelText: 'Vínculo / Parentesco',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── SECCIÓN 4: COBERTURA Y ATENCIÓN MÉDICA ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🏥', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '4. Cobertura y Red Médica',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.5, color: AppColors.border),

                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: TextFormField(
                                controller: _epsController,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'EPS / Aseguradora',
                                  hintText: 'Ej: SURA, Sanitas, Compensar',
                                  prefixIcon: Icon(Icons.health_and_safety_outlined, color: AppColors.primaryTeal),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 5,
                              child: DropdownButtonFormField<String>(
                                initialValue: _regimenEps,
                                isExpanded: true,
                                items: _regimenesEps.map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r, style: const TextStyle(fontSize: 13)),
                                )).toList(),
                                onChanged: (val) => setState(() => _regimenEps = val ?? 'Contributivo'),
                                decoration: const InputDecoration(labelText: 'Régimen EPS'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: TextFormField(
                                controller: _medicoTratanteController,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Médico de Cabecera',
                                  hintText: 'Ej: Dr. Ramírez',
                                  prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.primaryTeal),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: _telefonoMedicoController,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(
                                  labelText: 'Tel. Médico (10 dígitos)',
                                  hintText: 'Ej: 6013456789 o 3151234567',
                                ),
                                validator: (val) => _validarTelefonoColombia(val, obligatorio: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _clinicaPreferidaController,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Clínica / Hospital de Urgencias Preferido',
                            hintText: 'Ej: Clínica Reina Sofía',
                            prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.primaryTeal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── SECCIÓN 5: MIS TRATAMIENTOS MÉDICOS ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Text('🩺', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '5. Mis Tratamientos Médicos',
                                      style: AppTypography.subtitulo().copyWith(
                                        color: AppColors.primaryTeal,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _abrirAddTratamiento,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nuevo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.5, color: AppColors.border),
                        const Text(
                          'Aquí puedes registrar tus diagnósticos clínicos (ej: Hipertensión, Diabetes) para asociar tus medicamentos y controlar tu tratamiento.',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        ref.watch(tratamientosNotifierProvider).when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: AppColors.primaryTeal),
                            ),
                          ),
                          error: (err, _) => Center(
                            child: Text('Error al cargar tratamientos: $err', style: const TextStyle(color: AppColors.emergencyRed)),
                          ),
                          data: (trats) {
                            if (trats.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Column(
                                  children: [
                                    Text('📋', style: TextStyle(fontSize: 32)),
                                    SizedBox(height: 8),
                                    Text(
                                      'Aún no has registrado tratamientos',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Toca en "+ Nuevo" para agregar tu primer diagnóstico o terapia médica.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: trats.map((trat) {
                                return TratamientoCard(
                                  tratamiento: trat,
                                  onToggleEstado: () async {
                                    final nuevo = trat.esCompletado ? 'activo' : 'completado';
                                    await ref.read(tratamientosNotifierProvider.notifier).cambiarEstado(trat.id, nuevo);
                                  },
                                  onEdit: () async {
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => AddTratamientoDialog(tratamiento: trat),
                                    );
                                    if (result != null) {
                                      try {
                                        await ref.read(tratamientosNotifierProvider.notifier).updateTratamiento(trat.id, result);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('✅ Tratamiento para ${result['diagnostico']} actualizado', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              backgroundColor: AppColors.healthGreen,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('❌ Error al actualizar tratamiento: $e', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              backgroundColor: AppColors.emergencyRed,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('¿Eliminar tratamiento?'),
                                        content: Text('Se eliminará "${trat.diagnostico}". Los medicamentos vinculados se conservarán.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(tratamientosNotifierProvider.notifier).deleteTratamiento(trat.id);
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── SECCIÓN 6: HISTORIAL CLÍNICO Y ANTECEDENTES ──
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '6. Historial Clínico y Antecedentes',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.5, color: AppColors.border),

                        TextFormField(
                          controller: _alergiasController,
                          maxLines: 2,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Alergias Conocidas (Medicamentos / Alimentos)',
                            hintText: 'Ej: Penicilina, mariscos, polen (o Ninguna)',
                            prefixIcon: Icon(Icons.medical_information_outlined, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _condicionesController,
                          maxLines: 2,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Enfermedades o Diagnósticos Crónicos',
                            hintText: 'Ej: Hipertensión arterial, Diabetes, Artrosis',
                            prefixIcon: Icon(Icons.favorite_outline, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _cirugiasController,
                          maxLines: 2,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Cirugías o Antecedentes Quirúrgicos',
                            hintText: 'Ej: Cirugía de cadera (2018), Cataratas',
                            prefixIcon: Icon(Icons.healing_outlined, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _dispositivosController,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Dispositivos de Apoyo (Lentes, Bastón, Audífono)',
                            hintText: 'Ej: Lentes para lectura, bastón',
                            prefixIcon: Icon(Icons.hearing_outlined, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _antecedentesFamiliaresController,
                          maxLines: 2,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Antecedentes Familiares Importantes',
                            hintText: 'Ej: Madre hipertensa, padre con diabetes tipo 2',
                            prefixIcon: Icon(Icons.family_restroom_outlined, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _restriccionesAlimentariasController,
                          maxLines: 2,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Restricciones Alimentarias / Dieta Especial',
                            hintText: 'Ej: Dieta baja en sodio, hipoglúcida, sin gluten',
                            prefixIcon: Icon(Icons.restaurant_outlined, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _notasAdicionalesController,
                          maxLines: 2,
                          style: AppTypography.cuerpo(),
                          decoration: const InputDecoration(
                            labelText: 'Notas Adicionales de Cuidado / Observaciones',
                            hintText: 'Ej: Cuidados especiales, preferencias en la atención',
                            prefixIcon: Icon(Icons.note_alt_outlined, color: AppColors.primaryTeal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── SECCIÓN 7: PROTECCIÓN DE DATOS Y HABEAS DATA ──
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _aceptoHabeasData ? AppColors.healthGreen : AppColors.primaryTeal.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  color: AppColors.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('⚖️', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '7. Protección de Datos y Habeas Data',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.5, color: AppColors.border),
                        const Text(
                          'En cumplimiento del Régimen General de Protección de Datos Personales de Colombia (Ley 1581 de 2012), la información sobre salud, diagnósticos médicos y medicamentos es clasificada como DATOS SENSIBLES.',
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.security_rounded, color: AppColors.primaryTeal, size: 24),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tus datos tienen como finalidad exclusiva la gestión de tu bienestar, recordatorios de tomas y atención ante emergencias. No serán compartidos con terceros sin tu consentimiento.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const HabeasDataDialog(),
                            );
                          },
                          icon: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryTeal, size: 20),
                          label: const Text(
                            'Leer Política Completa y Derechos ARCO',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryTeal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _aceptoHabeasData,
                          activeColor: AppColors.healthGreen,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Autorizo de manera previa, expresa e informada el tratamiento de mis datos personales sensibles de salud.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            _aceptoHabeasData
                                ? '✓ Consentimiento otorgado conforme a la ley colombiana'
                                : '⚠️ Requerido para guardar y sincronizar tu ficha médica',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _aceptoHabeasData ? AppColors.healthGreen : AppColors.emergencyRed,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _aceptoHabeasData = val ?? false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── BOTÓN GUARDAR FICHA MÉDICA (64dp de alto) ──
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarFichaMedica,
                    icon: _guardando 
                        ? const SizedBox.shrink()
                        : const Icon(Icons.save_rounded, size: 28),
                    label: _guardando
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : const Text('Guardar Ficha Médica', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
