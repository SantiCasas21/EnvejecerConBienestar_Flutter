import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../perfil/presentation/widgets/habeas_data_dialog.dart';
import '../providers/cuidador_provider.dart';

class BienvenidaCuidadorDialog extends ConsumerStatefulWidget {
  final String? initialNombre;
  const BienvenidaCuidadorDialog({super.key, this.initialNombre});

  static Future<bool?> mostrar(BuildContext context, {String? nombre}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BienvenidaCuidadorDialog(initialNombre: nombre),
    );
  }

  @override
  ConsumerState<BienvenidaCuidadorDialog> createState() =>
      _BienvenidaCuidadorDialogState();
}

class _BienvenidaCuidadorDialogState
    extends ConsumerState<BienvenidaCuidadorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  final _telefonoController = TextEditingController();
  final _codigoPacienteController = TextEditingController();

  String _parentesco = 'Hijo/a';
  bool _aceptoHabeasData = false;
  bool _guardando = false;
  String? _errorMensaje;

  final List<String> _parentescos = [
    'Hijo/a',
    'Cónyuge / Pareja',
    'Hermano/a',
    'Nieto/a',
    'Cuidador/a Principal',
    'Familiar cercano',
    'Amigo/a de confianza',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.initialNombre ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _codigoPacienteController.dispose();
    super.dispose();
  }

  Future<void> _guardarYVincular() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aceptoHabeasData) {
      setState(() {
        _errorMensaje =
            'Por favor autoriza el tratamiento de datos para continuar.';
      });
      return;
    }

    final codigo = _codigoPacienteController.text.trim().toUpperCase();

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    if (codigo.isNotEmpty) {
      final error = await ref
          .read(cuidadorNotifierProvider.notifier)
          .vincularPaciente(codigo, parentesco: _parentesco);

      if (error != null && mounted) {
        setState(() {
          _guardando = false;
          _errorMensaje = error;
        });
        return;
      }
    }

    if (mounted) {
      setState(() => _guardando = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera Cálida y de Acompañamiento
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.primaryTeal, width: 2.5),
                    ),
                    child: const Center(
                      child: Text('🤝', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  '¡Bienvenido/a Cuidador/a!',
                  textAlign: TextAlign.center,
                  style: AppTypography.titulo().copyWith(
                    fontSize: 24,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tu acompañamiento transforma vidas. Configura tus datos básicos de contacto y vincula a tu ser querido.',
                  textAlign: TextAlign.center,
                  style: AppTypography.cuerpo().copyWith(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Mensaje de Error si ocurre
                if (_errorMensaje != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.pendingBackground,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.emergencyRed, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.emergencyRed, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMensaje!,
                            style: const TextStyle(
                              color: AppColors.emergencyRed,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── SECCIÓN 1: DATOS BÁSICOS DEL CUIDADOR ──
                Text(
                  '👤 Tus Datos Básicos',
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const Divider(
                    height: 16, thickness: 1.5, color: AppColors.border),

                // Nombre completo
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  style: AppTypography.cuerpo().copyWith(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Tu Nombre completo',
                    hintText: 'Ej: Carolina Gómez',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.primaryTeal, size: 26),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Por favor ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 14),

                // Teléfono de contacto y Parentesco
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.cuerpo().copyWith(fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de contacto',
                          hintText: 'Ej: 3001234567',
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: AppColors.primaryTeal, size: 26),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu teléfono';
                          }
                          final digitos = val.replaceAll(RegExp(r'\D'), '');
                          if (digitos.length < 10) {
                            return 'Mínimo 10 dígitos';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        value: _parentesco,
                        isExpanded: true,
                        items: _parentescos
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p,
                                      style: const TextStyle(fontSize: 15)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(
                            () => _parentesco = val ?? 'Hijo/a'),
                        decoration: const InputDecoration(
                          labelText: 'Parentesco',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── SECCIÓN 2: VINCULACIÓN DEL ADULTO MAYOR ──
                Text(
                  '🔗 Vincular Adulto Mayor',
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const Divider(
                    height: 16, thickness: 1.5, color: AppColors.border),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: AppColors.primaryTeal, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_rounded,
                              color: AppColors.primaryDark, size: 26),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ingresa el Código de tu Familiar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'El adulto mayor puede ver su código único (ej: ECB-1001) en la pantalla de su perfil.',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _codigoPacienteController,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppColors.primaryTeal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ej: ECB-1001',
                          hintStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 1.0,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primaryTeal, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── HABEAS DATA ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _aceptoHabeasData
                        ? AppColors.primaryLight.withValues(alpha: 0.3)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _aceptoHabeasData
                          ? AppColors.primaryTeal.withValues(alpha: 0.4)
                          : Colors.amber.shade400,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _aceptoHabeasData,
                        activeColor: AppColors.primaryTeal,
                        onChanged: (val) =>
                            setState(() => _aceptoHabeasData = val ?? false),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                  () => _aceptoHabeasData = !_aceptoHabeasData),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Autorizo el tratamiento de datos y supervisión conforme a la Ley 1581 de 2012 (Habeas Data).',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => const HabeasDataDialog(),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '📘 Consultar Política de Privacidad',
                                  style: TextStyle(
                                    fontSize: 12,
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
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Botón Vincular y Comenzar
                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarYVincular,
                    icon: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 24),
                    label: Text(
                      _codigoPacienteController.text.trim().isNotEmpty
                          ? 'Vincular y Comenzar a Cuidar 💙'
                          : 'Guardar y Continuar al Panel 🌟',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.textInverse,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón Omitir por ahora
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Ingresar código de paciente más tarde',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
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
