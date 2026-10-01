import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/call_service.dart';
import '../../../auth/data/models/paciente_vinculado_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/cuidador_provider.dart';
import '../../../auth/presentation/widgets/bienvenida_cuidador_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class CuidadorDashboardScreen extends ConsumerStatefulWidget {
  const CuidadorDashboardScreen({super.key});

  @override
  ConsumerState<CuidadorDashboardScreen> createState() =>
      _CuidadorDashboardScreenState();
}

class _CuidadorDashboardScreenState
    extends ConsumerState<CuidadorDashboardScreen> {
  bool _onboardingRevisado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarOnboardingCuidador();
    });
  }

  void _verificarOnboardingCuidador() async {
    if (_onboardingRevisado || !mounted) return;
    _onboardingRevisado = true;

    final user = ref.read(authNotifierProvider).user;
    if (user == null || !user.esCuidador) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'onboarding_cuidador_${user.id}';
    final yaVisto = prefs.getBool(key) ?? false;

    if (!yaVisto && mounted) {
      await prefs.setBool(key, true);
      final resultado = await BienvenidaCuidadorDialog.mostrar(
        context,
        nombre: user.nombre,
      );
      if (resultado == true && mounted) {
        ref.read(cuidadorNotifierProvider.notifier).cargarPacientes();
      }
    }
  }

  Future<void> _enviarWhatsAppRecordatorio(PacienteVinculadoModel paciente,
      [String? nombreMed]) async {
    final tel = paciente.telefonoContactoDirecto ?? paciente.telefono;
    final telLimpio = tel?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    final String mensaje;
    if (nombreMed != null && nombreMed.isNotEmpty) {
      mensaje =
          '¡Hola ${paciente.nombre}! 🌸 Te escribo con cariño para recordarte tomar tu medicamento "$nombreMed". ¡Un abrazo!';
    } else {
      mensaje =
          '¡Hola ${paciente.nombre}! 🌸 Te escribo para consultar cómo vas hoy con tus tomas de medicamentos y saber cómo te has sentido. ¡Cuídate mucho!';
    }

    if (telLimpio.isNotEmpty) {
      final uri = Uri.parse(
          'https://wa.me/57$telLimpio?text=${Uri.encodeComponent(mensaje)}');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }

    await Share.share(mensaje, subject: 'Recordatorio de Salud');
  }

  void _mostrarDialogoVincular() {
    final codigoController = TextEditingController();
    String parentesco = 'Hijo/a';
    final formKey = GlobalKey<FormState>();
    bool cargando = false;
    String? errorLocal;

    final parentescos = [
      'Hijo/a',
      'Cónyuge / Pareja',
      'Hermano/a',
      'Nieto/a',
      'Cuidador/a Principal',
      'Familiar cercano',
      'Amigo/a de confianza',
      'Otro',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded,
                    color: AppColors.primaryTeal, size: 28),
                SizedBox(width: 10),
                Text(
                  'Vincular Paciente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pídele a tu familiar su código único de vinculación (visible en su perfil):',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    if (errorLocal != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.pendingBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.emergencyRed),
                        ),
                        child: Text(
                          errorLocal!,
                          style: const TextStyle(
                            color: AppColors.emergencyRed,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: codigoController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.primaryTeal,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Código del Adulto Mayor',
                        hintText: 'Ej: ECB-1001',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa el código'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: parentesco,
                      items: parentescos
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p,
                                    style: const TextStyle(fontSize: 16)),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => parentesco = val ?? 'Hijo/a'),
                      decoration: InputDecoration(
                        labelText: 'Tu Parentesco',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: cargando ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: cargando
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setModalState(() {
                            cargando = true;
                            errorLocal = null;
                          });
                          final error = await ref
                              .read(cuidadorNotifierProvider.notifier)
                              .vincularPaciente(
                                codigoController.text.trim(),
                                parentesco: parentesco,
                              );
                          if (error != null) {
                            setModalState(() {
                              cargando = false;
                              errorLocal = error;
                            });
                          } else {
                            Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    '🎉 ¡Paciente vinculado con éxito!',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: AppColors.healthGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Vincular',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmarDesvincular(PacienteVinculadoModel paciente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('¿Desvincular paciente?'),
        content: Text(
          '¿Estás seguro de que deseas dejar de supervisar a ${paciente.nombre}? Podrás volver a vincularlo ingresando su código.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final exito = await ref
                  .read(cuidadorNotifierProvider.notifier)
                  .desvincularPaciente(paciente.id);
              if (mounted && exito) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Has desvinculado a ${paciente.nombre}.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    backgroundColor: AppColors.emergencyRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
  }

  void _verFichaClinica(PacienteVinculadoModel paciente) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        AppColors.generarColorPorNombre(paciente.nombre),
                    child: Text(
                      paciente.nombre.isNotEmpty
                          ? paciente.nombre[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paciente.nombre,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${paciente.parentesco} • Código: ${paciente.codigoVinculacion ?? "N/A"}',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1.5),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información Médica
                      const Text(
                        '📋 Datos Clínicos y de Salud',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal),
                      ),
                      const SizedBox(height: 10),
                      _buildFilaDetalle('Edad:', '${paciente.edad ?? "Sin registrar"} años'),
                      _buildFilaDetalle('Tipo de Sangre:', paciente.tipoSangre ?? 'O+'),
                      _buildFilaDetalle('EPS / Aseguradora:', paciente.eps ?? 'No especificada'),
                      _buildFilaDetalle('Alergias:', paciente.alergias ?? 'Ninguna'),
                      _buildFilaDetalle('Condiciones Médicas:', paciente.condiciones ?? 'Ninguna'),
                      const SizedBox(height: 18),

                      // Red de Contacto
                      const Text(
                        '📞 Contactos de Urgencia',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emergencyRed),
                      ),
                      const SizedBox(height: 10),
                      _buildFilaDetalle(
                        'Contacto SOS:',
                        '${paciente.contactoEmergenciaNombre ?? "Sin registrar"} (${paciente.contactoEmergenciaTelefono ?? "Sin tel"})',
                      ),
                      _buildFilaDetalle('Teléfono Paciente:', paciente.telefono ?? 'No registrado'),
                      const SizedBox(height: 18),

                      // Resumen Medicación
                      const Text(
                        '💊 Medicación y Tomas de Hoy',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 10),
                      _buildFilaDetalle(
                        'Tomas Cumplidas:',
                        '${paciente.tomasCumplidas} de ${paciente.totalMedicamentos}',
                      ),
                      _buildFilaDetalle(
                        'Dosis Pendientes:',
                        '${paciente.tomasPendientes}',
                      ),
                      if (paciente.tieneAlertasStock) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.pendingBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.emergencyRed),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.emergencyRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Alerta de Botiquín: Stock bajo en ${paciente.medicamentosAlerta.join(", ")}',
                                  style: const TextStyle(
                                    color: AppColors.emergencyRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (paciente.telefonoContactoDirecto != null) ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => CallService.realizarLlamada(
                        paciente.telefonoContactoDirecto!),
                    icon: const Icon(Icons.call, size: 22),
                    label: Text(
                      'Llamar a ${paciente.nombre}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.healthGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilaDetalle(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authNotifierProvider).user;
    final pacientesAsync = ref.watch(cuidadorNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Panel de Supervisión',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: 'Vincular Paciente',
            icon: const Icon(Icons.person_add_alt_1_rounded,
                size: 28, color: AppColors.primaryTeal),
            onPressed: _mostrarDialogoVincular,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryTeal,
        onRefresh: () async {
          await ref.read(cuidadorNotifierProvider.notifier).cargarPacientes();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera de Saludo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryTeal, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🤝', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola, ${authUser?.nombre ?? "Cuidador/a"}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Supervisión de salud familiar en tiempo real',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Botón Vincular Paciente dentro del banner
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _mostrarDialogoVincular,
                        icon: const Icon(Icons.add_link_rounded, size: 22),
                        label: const Text(
                          'Vincular Nuevo Adulto Mayor',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Título de la sección
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👥 Pacientes Supervisados',
                    style: AppTypography.subtitulo().copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  pacientesAsync.maybeWhen(
                    data: (lista) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${lista.length} activo(s)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lista de Pacientes o Estado Vacío
              pacientesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                ),
                error: (err, _) => Card(
                  color: AppColors.pendingBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error al cargar pacientes: $err'),
                  ),
                ),
                data: (pacientes) {
                  if (pacientes.isEmpty) {
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            const Text('🌱', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            const Text(
                              'Aún no has vinculado ningún paciente',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Pídele a tu familiar adulto mayor su código (ej: ECB-1001) para comenzar a supervisar su salud.',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _mostrarDialogoVincular,
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Vincular a mi primer familiar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(220, 48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: pacientes.map((p) {
                      return _buildPacienteCard(p);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPacienteCard(PacienteVinculadoModel p) {
    final avatarColor = AppColors.generarColorPorNombre(p.nombre);
    final initial = p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : 'P';
    final tieneAlertas = p.tieneAlertasStock;
    final todasTomadas = p.todasTomasCompletadas;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 2.5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Avatar, Nombre, Código y Menú
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: avatarColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.codigoVinculacion ?? 'ECB-1001',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.parentesco,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'detalle') {
                      _verFichaClinica(p);
                    } else if (val == 'whatsapp') {
                      _enviarWhatsAppRecordatorio(p);
                    } else if (val == 'desvincular') {
                      _confirmarDesvincular(p);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'detalle',
                      child: Row(
                        children: [
                          Icon(Icons.assignment_outlined,
                              color: AppColors.primaryTeal, size: 20),
                          SizedBox(width: 10),
                          Text('Ficha Clínica Completa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'whatsapp',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: AppColors.healthGreen, size: 20),
                          SizedBox(width: 10),
                          Text('Escribir por WhatsApp'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'desvincular',
                      child: Row(
                        children: [
                          Icon(Icons.link_off_rounded,
                              color: AppColors.emergencyRed, size: 20),
                          SizedBox(width: 10),
                          Text('Desvincular Paciente'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1.2),

            // Resumen de Tomas del Día
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('💊', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Tomas de Hoy: ${p.tomasCumplidas}/${p.totalMedicamentos}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: todasTomadas
                        ? AppColors.completedLight
                        : AppColors.pendingBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    todasTomadas
                        ? '✅ Al día'
                        : '⏳ ${p.tomasPendientes} pendiente(s)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: todasTomadas
                          ? AppColors.primaryDark
                          : AppColors.emergencyRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: p.porcentajeTomas,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  todasTomadas ? AppColors.healthGreen : AppColors.primaryTeal,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Indicador de Botiquín (badge discreto si hay alertas)
            if (tieneAlertas) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.pendingBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.emergencyRed.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.emergencyRed, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Botiquín: ${p.alertasStock} medicamento(s) con stock bajo',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emergencyRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Botón Destacado: Ver Medicinas y Botiquín
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(pacienteSeleccionadoIdProvider.notifier).state =
                      p.id;
                  context.push('/medicamentos');
                },
                icon: const Icon(Icons.medication_rounded, size: 22),
                label: const Text(
                  '💊 Ver Medicinas y Botiquín',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Botones Secundarios: Ficha Clínica, WhatsApp y Llamada
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verFichaClinica(p),
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('Ficha Clínica',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _enviarWhatsAppRecordatorio(p),
                  tooltip: 'Recordatorio WhatsApp',
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.completedLight,
                    foregroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(44, 44),
                  ),
                ),
                if (p.telefonoContactoDirecto != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        CallService.realizarLlamada(p.telefonoContactoDirecto!),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Llamar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.healthGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(90, 44),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
