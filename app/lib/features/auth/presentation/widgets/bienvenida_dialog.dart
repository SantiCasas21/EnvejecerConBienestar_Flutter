import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../perfil/data/models/perfil_model.dart';
import '../../../perfil/presentation/widgets/habeas_data_dialog.dart';

class BienvenidaDialog extends StatefulWidget {
  final String? initialNombre;
  const BienvenidaDialog({super.key, this.initialNombre});

  @override
  State<BienvenidaDialog> createState() => _BienvenidaDialogState();
}

class _BienvenidaDialogState extends State<BienvenidaDialog> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _fechaNacimiento;
  final _edadController = TextEditingController();
  final _telefonoPropioController = TextEditingController();
  final _epsController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _condicionesController = TextEditingController();
  
  // Contacto de Emergencia
  final _contactoEmergenciaNombreController = TextEditingController();
  final _contactoEmergenciaTelefonoController = TextEditingController();
  String _contactoEmergenciaParentesco = 'Hijo/a';
  
  String _tipoSangre = 'O+';
  String _genero = 'Femenino';
  bool _aceptoHabeasData = false;

  final List<String> _tiposSangre = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  final List<String> _generos = ['Femenino', 'Masculino', 'Otro'];
  final List<String> _parentescos = ['Hijo/a', 'Cónyuge', 'Hermano/a', 'Nieto/a', 'Cuidador/a', 'Amigo/a', 'Otro'];

  @override
  void dispose() {
    _edadController.dispose();
    _telefonoPropioController.dispose();
    _epsController.dispose();
    _alergiasController.dispose();
    _condicionesController.dispose();
    _contactoEmergenciaNombreController.dispose();
    _contactoEmergenciaTelefonoController.dispose();
    super.dispose();
  }

  void _seleccionarFechaNacimiento() async {
    final now = DateTime.now();
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 70, now.month, now.day),
      firstDate: DateTime(1910),
      lastDate: now,
      helpText: 'Selecciona tu Fecha de Nacimiento',
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

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      if (!_aceptoHabeasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚖️ Debes autorizar el tratamiento de datos (Habeas Data) para continuar.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: AppColors.emergencyRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final fechaStr = _fechaNacimiento != null 
          ? '${_fechaNacimiento!.year.toString().padLeft(4, '0')}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}'
          : null;

      final perfil = PerfilModel(
        fechaNacimiento: fechaStr,
        edad: int.tryParse(_edadController.text.trim()),
        genero: _genero,
        tipoSangre: _tipoSangre,
        eps: _epsController.text.trim().isEmpty ? 'No especificada' : _epsController.text.trim(),
        telefono: _telefonoPropioController.text.trim(),
        alergias: _alergiasController.text.trim().isEmpty ? 'Ninguna' : _alergiasController.text.trim(),
        condiciones: _condicionesController.text.trim().isEmpty ? 'Ninguna' : _condicionesController.text.trim(),
        contactoEmergenciaNombre: _contactoEmergenciaNombreController.text.trim(),
        contactoEmergenciaTelefono: _contactoEmergenciaTelefonoController.text.trim(),
        contactoEmergenciaParentesco: _contactoEmergenciaParentesco,
        aceptoHabeasData: true,
      );
      Navigator.of(context).pop(perfil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto = _fechaNacimiento != null 
        ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
        : 'Toca para elegir fecha';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera Cálida
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🌼', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  '¡Te damos la bienvenida!',
                  textAlign: TextAlign.center,
                  style: AppTypography.titulo().copyWith(
                    fontSize: 24,
                    color: AppColors.primaryTeal,
                  ),
                ),
                if (widget.initialNombre != null && widget.initialNombre!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.initialNombre!,
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitulo().copyWith(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Completa tu ficha de salud para personalizar tus alarmas y reporte médico:',
                  textAlign: TextAlign.center,
                  style: AppTypography.pequeno().copyWith(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // ── SECCIÓN 1: DATOS VITALES ──
                Text(
                  '📋 1. Datos Personales y Vitales',
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const Divider(height: 16, thickness: 1.5, color: AppColors.border),
                
                // Fecha de Nacimiento / Cumpleaños (con DatePicker)
                InkWell(
                  onTap: _seleccionarFechaNacimiento,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
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
                                fechaTexto,
                                style: TextStyle(
                                  fontSize: 18,
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

                // Edad y Tipo de Sangre
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
                          hintText: 'Ej: 72',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipoSangre,
                        items: _tiposSangre
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.cuerpo())))
                            .toList(),
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

                // Género y EPS
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _genero,
                        items: _generos
                            .map((g) => DropdownMenuItem(value: g, child: Text(g, style: AppTypography.cuerpo())))
                            .toList(),
                        onChanged: (val) => setState(() => _genero = val ?? 'Femenino'),
                        decoration: const InputDecoration(
                          labelText: 'Género',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _epsController,
                        style: AppTypography.cuerpo(),
                        decoration: const InputDecoration(
                          labelText: 'EPS / Seguro',
                          hintText: 'Ej: Sura, Sanitas',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── SECCIÓN 2: CONTACTO DE EMERGENCIA SOS ──
                Text(
                  '🆘 2. Contacto de Emergencia SOS',
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emergencyRed,
                  ),
                ),
                const Divider(height: 16, thickness: 1.5, color: AppColors.border),

                TextFormField(
                  controller: _contactoEmergenciaNombreController,
                  style: AppTypography.cuerpo(),
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Familiar / Cuidador',
                    hintText: 'Ej: Carlos (Hijo)',
                    prefixIcon: Icon(Icons.person_pin_circle_outlined, color: AppColors.emergencyRed),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _contactoEmergenciaTelefonoController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.cuerpo(),
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de Urgencias (10 dígitos)',
                          hintText: 'Ej: 3001234567',
                          prefixIcon: Icon(Icons.phone_in_talk_outlined, color: AppColors.emergencyRed),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final digitos = val.replaceAll(RegExp(r'\D'), '');
                            if (digitos.length < 10) return 'Mínimo 10 dígitos (ej: 3001234567)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        initialValue: _contactoEmergenciaParentesco,
                        items: _parentescos
                            .map((p) => DropdownMenuItem(value: p, child: Text(p, style: AppTypography.pequeno())))
                            .toList(),
                        onChanged: (val) => setState(() => _contactoEmergenciaParentesco = val ?? 'Hijo/a'),
                        decoration: const InputDecoration(
                          labelText: 'Parentesco',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── SECCIÓN 3: ANTECEDENTES Y ALERGIAS ──
                Text(
                  '🩺 3. Antecedentes y Cuidados',
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const Divider(height: 16, thickness: 1.5, color: AppColors.border),

                // Alergias
                TextFormField(
                  controller: _alergiasController,
                  style: AppTypography.cuerpo(),
                  decoration: const InputDecoration(
                    labelText: 'Alergias conocidas',
                    hintText: 'Ej: Penicilina, mariscos (o Ninguna)',
                    prefixIcon: Icon(Icons.medical_information_outlined, color: AppColors.primaryTeal),
                  ),
                ),
                const SizedBox(height: 12),

                // Condiciones / Enfermedades
                TextFormField(
                  controller: _condicionesController,
                  style: AppTypography.cuerpo(),
                  decoration: const InputDecoration(
                    labelText: 'Enfermedades conocidas / Diagnósticos',
                    hintText: 'Ej: Hipertensión, Diabetes (o Ninguna)',
                    prefixIcon: Icon(Icons.favorite_outline, color: AppColors.primaryTeal),
                  ),
                ),
                const SizedBox(height: 20),

                // ── AUTORIZACIÓN LEGAL DE HABEAS DATA ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _aceptoHabeasData
                        ? AppColors.primaryLight.withValues(alpha: 0.4)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _aceptoHabeasData
                          ? AppColors.primaryTeal.withValues(alpha: 0.4)
                          : Colors.amber.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _aceptoHabeasData,
                            activeColor: AppColors.primaryTeal,
                            onChanged: (val) => setState(() => _aceptoHabeasData = val ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _aceptoHabeasData = !_aceptoHabeasData),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  'Autorizo el tratamiento de mis datos personales y de salud conforme a la Ley 1581 de 2012 (Habeas Data).',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 48, bottom: 4),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const HabeasDataDialog(),
                            );
                          },
                          child: const Text(
                            '📘 Leer Política de Privacidad y Derechos ARCO',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Guardar y Empezar
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.textInverse,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                    ),
                    child: const Text(
                      '¡Guardar Ficha y Comenzar! 🌟',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
