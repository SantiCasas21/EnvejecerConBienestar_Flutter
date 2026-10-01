import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/call_service.dart';
import '../../../../core/utils/pdf_report_service.dart';
import '../../../auth/data/models/paciente_vinculado_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/cuidador_provider.dart';
import '../../../home/presentation/providers/metas_provider.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../data/models/medicamento_model.dart';
import '../providers/medicamentos_provider.dart';
import '../providers/tratamientos_provider.dart';
import '../widgets/add_medicamento_dialog.dart';
import '../widgets/botiquin_inventario_tab.dart';
import '../widgets/medicamento_card.dart';
import '../widgets/medicamento_popup_dialog.dart';

class MedicamentosScreen extends ConsumerStatefulWidget {
  const MedicamentosScreen({super.key});

  @override
  ConsumerState<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends ConsumerState<MedicamentosScreen> {
  int _vistaSeleccionada = 0; // 0: Tomas Diarias, 1: Mi Botiquín (Inventario)

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

  final List<Map<String, dynamic>> _sugerencias = const [
    {
      'nombre': 'Acetaminofén',
      'icono': '💊',
      'color_icono': '#0D9488',
      'miligramos': '500',
      'frecuencia': 8,
      'notas': 'Para dolor o malestar general',
      'cantidad_restante': 30,
    },
    {
      'nombre': 'Ibuprofeno',
      'icono': '💊',
      'color_icono': '#818CF8',
      'miligramos': '400',
      'frecuencia': 8,
      'notas': 'Antiinflamatorio',
      'cantidad_restante': 20,
    },
    {
      'nombre': 'Vitamina C',
      'icono': '🍊',
      'color_icono': '#22C55E',
      'miligramos': '500',
      'frecuencia': 24,
      'notas': 'Suplemento diario de defensas',
      'cantidad_restante': 30,
    },
    {
      'nombre': 'Losartán',
      'icono': '💊',
      'color_icono': '#0D9488',
      'miligramos': '50',
      'frecuencia': 12,
      'notas': 'Control de presión arterial',
      'cantidad_restante': 30,
    },
    {
      'nombre': 'Metformina',
      'icono': '💊',
      'color_icono': '#64748B',
      'miligramos': '850',
      'frecuencia': 24,
      'notas': 'Control de glucosa con el desayuno',
      'cantidad_restante': 30,
    },
    {
      'nombre': 'Omeprazol',
      'icono': '💊',
      'color_icono': '#0D9488',
      'miligramos': '20',
      'frecuencia': 24,
      'notas': 'Protector gástrico en ayunas',
      'cantidad_restante': 30,
    },
  ];

  void _abrirAdd(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddMedicamentoDialog(),
    );

    if (result != null) {
      try {
        await ref.read(medicamentosNotifierProvider.notifier).addMedicamento(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['nombre']} registrado exitosamente', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              content: Text('❌ Error al guardar medicamento: $e', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.emergencyRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  void _agregarSugerencia(BuildContext context, Map<String, dynamic> sug) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Agregar ${sug['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Deseas agregar ${sug['nombre']} (${sug['miligramos']} mg cada ${sug['frecuencia']}h) a tu medicación diaria?',
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 17, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Sí, agregar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final now = TimeOfDay.now();
      final horaStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
      final payload = Map<String, dynamic>.from(sug);
      payload['hora_alarma'] = horaStr;
      
      try {
        await ref.read(medicamentosNotifierProvider.notifier).addMedicamento(payload);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${sug['nombre']} agregado a tus tomas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              content: Text('❌ Error al agregar medicamento: $e', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.emergencyRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  void _generarPDF(BuildContext context) async {
    final auth = ref.read(authNotifierProvider);
    final user = auth.user;
    if (user == null) return;

    final perfil = ref.read(perfilNotifierProvider).value;
    final medicamentos = ref.read(medicamentosNotifierProvider).value ?? [];
    final metas = ref.read(metasNotifierProvider).value ?? [];
    final tratamientos = ref.read(tratamientosNotifierProvider).value ?? [];

    await PdfReportService.generarYCompartirReporte(
      usuario: user,
      perfil: perfil,
      tratamientos: tratamientos,
      medicamentos: medicamentos,
      metas: metas,
    );
  }

  void _toggleTomado(BuildContext context, Medicamento med) async {
    final id = med.id;
    await ref.read(medicamentosNotifierProvider.notifier).toggleTomado(id);

    final updatedMed = ref.read(medicamentosNotifierProvider).value?.firstWhere((m) => m.id == id, orElse: () => med);
    if (updatedMed != null && (updatedMed.estaTomado ?? false) && updatedMed.alertaInventario && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ ¡Inventario Bajo! Quedan solo ${updatedMed.cantidadRestante} pastillas de ${updatedMed.nombre}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.emergencyRed,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildPillTab({required int index, required String label, required IconData icon}) {
    final activo = _vistaSeleccionada == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vistaSeleccionada = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          decoration: BoxDecoration(
            color: activo ? AppColors.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: activo
                ? [const BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: activo ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: activo ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTomasView(List<Medicamento> medicamentos, List<dynamic> tratamientos) {
    return RefreshIndicator(
      color: AppColors.primaryTeal,
      onRefresh: () async {
        ref.invalidate(medicamentosNotifierProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner Conexión con Perfil y Tratamientos ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🩺', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tratamientos en tu Perfil',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tratamientos.isEmpty
                              ? 'Registra tus diagnósticos médicos para coordinar tus medicamentos.'
                              : '${tratamientos.length} tratamiento(s) registrado(s) en tu ficha médica.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/perfil'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Ver ➔', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Carrusel de Sugerencias Rápidas
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sugerencias Frecuentes',
                    style: AppTypography.subtitulo().copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 145,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _sugerencias.length,
                itemBuilder: (context, index) {
                  final sug = _sugerencias[index];
                  return Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(sug['icono'], style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        Text(
                          sug['nombre'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${sug['miligramos']} mg',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _agregarSugerencia(context, sug),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('+ Agregar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Lista de Medicinas Registradas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Tus Medicamentos (${medicamentos.length})',
                    style: AppTypography.subtitulo().copyWith(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primaryTeal),
                  label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                  onPressed: () => _abrirAdd(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (medicamentos.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Text('💊', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        'Aún no tienes medicamentos registrados',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Toca en "+ Agregar" en las sugerencias o pulsa el botón flotante.',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...medicamentos.map((med) {
                return MedicamentoCard(
                  medicamento: med,
                  onToggle: () => _toggleTomado(context, med),
                  onTap: () => MedicamentoPopupDialog.mostrar(context, med),
                );
              }),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCuidadorMedicamentosView(BuildContext context) {
    final pacientesAsync = ref.watch(cuidadorNotifierProvider);

    return pacientesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Supervisión de Medicación'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.emergencyRed),
                const SizedBox(height: 16),
                Text(
                  'No pudimos cargar tus familiares',
                  style: AppTypography.subtitulo(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(cuidadorNotifierProvider.notifier)
                      .cargarPacientes(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (pacientes) {
        if (pacientes.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Supervisión de Medicación',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    )
                  : null,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('👥', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No tienes adultos mayores vinculados',
                      style: AppTypography.subtitulo().copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Vincula a tu familiar con su código único (ej. ECB-1001) desde el panel para supervisar sus medicamentos y botiquín.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          context.pop();
                        } else {
                          context.go('/cuidador');
                        }
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Ir al Panel Principal',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final selId = ref.watch(pacienteSeleccionadoIdProvider);
        final pacienteActivo = pacientes.firstWhere(
          (p) => p.id == selId,
          orElse: () => pacientes.first,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Supervisión de Salud',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  )
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Column(
                children: [
                  // Selector Horizontal de Pacientes
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pacientes.length,
                      itemBuilder: (context, index) {
                        final p = pacientes[index];
                        final isSelected = p.id == pacienteActivo.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              p.nombre,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primaryTeal,
                            backgroundColor: Colors.white,
                            avatar: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppColors.primaryLight,
                              child: Text(
                                p.nombre.isNotEmpty
                                    ? p.nombre[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryTeal,
                                ),
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.border,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                ref
                                    .read(pacienteSeleccionadoIdProvider
                                        .notifier)
                                    .state = p.id;
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Segmented Tabs
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildPillTab(
                            index: 0,
                            label: 'Tomas de Hoy',
                            icon: Icons.medication_rounded),
                        _buildPillTab(
                            index: 1,
                            label: 'Botiquín Familiar',
                            icon: Icons.inventory_2_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: IndexedStack(
            index: _vistaSeleccionada,
            children: [
              _buildTomasCuidadorView(pacienteActivo),
              _buildBotiquinCuidadorView(pacienteActivo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTomasCuidadorView(PacienteVinculadoModel paciente) {
    final medsAsync =
        ref.watch(medicamentosPacienteCuidadorProvider(paciente.id));

    return RefreshIndicator(
      color: AppColors.primaryTeal,
      onRefresh: () async {
        ref.invalidate(medicamentosPacienteCuidadorProvider(paciente.id));
        await ref.read(cuidadorNotifierProvider.notifier).cargarPacientes();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de Identificación y Acciones Rápidas del Paciente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('🧓', style: TextStyle(fontSize: 28)),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Código: ${paciente.codigoVinculacion ?? "N/A"} · ${paciente.parentesco}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${paciente.porcentajeTomasEntero}% tomas completadas hoy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: paciente.porcentajeTomasEntero >= 80
                                    ? AppColors.healthGreen
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final tel = paciente.telefono ?? '';
                            if (tel.isNotEmpty) {
                              CallService.realizarLlamada(tel);
                            }
                          },
                          icon: const Icon(Icons.phone_in_talk, size: 20),
                          label: const Text('Llamar',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _enviarWhatsAppRecordatorio(paciente),
                          icon: const Text('💬', style: TextStyle(fontSize: 16)),
                          label: const Text('WhatsApp',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF15803D),
                            side: const BorderSide(
                                color: Color(0xFF22C55E), width: 1.5),
                            backgroundColor: const Color(0xFFF0FDF4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de Medicamentos del Paciente
            medsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryTeal),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.pendingBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.emergencyRed, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'No se pudieron cargar los medicamentos del paciente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                          medicamentosPacienteCuidadorProvider(paciente.id)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (meds) {
                if (meds.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text('💊', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 12),
                        Text(
                          '${paciente.nombre} no tiene medicamentos registrados',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Los medicamentos que el paciente o tú registren aparecerán aquí con su estado en tiempo real.',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Medicamentos Asignados (${meds.length})',
                          style: AppTypography.subtitulo().copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppColors.primaryTeal),
                          tooltip: 'Actualizar',
                          onPressed: () => ref.invalidate(
                              medicamentosPacienteCuidadorProvider(
                                  paciente.id)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...meds.map((med) {
                      final tomado = med.estaTomado ?? false;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: med.alertaInventario
                                ? AppColors.emergencyRed.withValues(alpha: 0.6)
                                : AppColors.border,
                            width: med.alertaInventario ? 2 : 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: tomado
                                        ? AppColors.healthGreen
                                            .withValues(alpha: 0.15)
                                        : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      med.icono,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.nombre,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${med.miligramos ?? ""} mg · Cada ${med.frecuencia ?? 8} horas',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (med.horaAlarma != null &&
                                          med.horaAlarma!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.alarm,
                                                size: 14,
                                                color: AppColors.primaryTeal),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Hora: ${med.horaAlarma}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryTeal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: tomado
                                        ? const Color(0xFFF0FDF4)
                                        : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: tomado
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tomado
                                            ? Icons.check_circle_rounded
                                            : Icons.schedule_rounded,
                                        size: 16,
                                        color: tomado
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB45309),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tomado ? 'Tomado' : 'Pendiente',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: tomado
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Stock y Recordatorio
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      med.alertaInventario
                                          ? Icons.warning_amber_rounded
                                          : Icons.inventory_2_outlined,
                                      size: 16,
                                      color: med.alertaInventario
                                          ? AppColors.emergencyRed
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Stock: ${med.cantidadRestante ?? 0} pastillas',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: med.alertaInventario
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: med.alertaInventario
                                            ? AppColors.emergencyRed
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!tomado)
                                  InkWell(
                                    onTap: () => _enviarWhatsAppRecordatorio(
                                        paciente, med.nombre),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFF22C55E)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text('💬',
                                              style: TextStyle(fontSize: 14)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Recordar por WA',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBotiquinCuidadorView(PacienteVinculadoModel paciente) {
    final medsAsync =
        ref.watch(medicamentosPacienteCuidadorProvider(paciente.id));

    return medsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.emergencyRed, size: 48),
              const SizedBox(height: 12),
              Text('Error al cargar botiquín: $err',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                    medicamentosPacienteCuidadorProvider(paciente.id)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (meds) => BotiquinInventarioTab(
        medicamentos: meds,
        pacienteId: paciente.id,
        onReabastecer: (medId, cant, medNombre) async {
          final medIdInt = int.tryParse(medId.toString()) ?? 0;
          final exito = await ref
              .read(cuidadorNotifierProvider.notifier)
              .reabastecerMedicamentoPaciente(paciente.id, medIdInt, cant);
          if (exito) {
            ref.invalidate(medicamentosPacienteCuidadorProvider(paciente.id));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authNotifierProvider).user;
    if (authUser != null && authUser.esCuidador) {
      return _buildCuidadorMedicamentosView(context);
    }

    final medicamentosAsync = ref.watch(medicamentosNotifierProvider);
    final tratamientosAsync = ref.watch(tratamientosNotifierProvider);
    final medicamentos = medicamentosAsync.value ?? [];
    final tratamientos = tratamientosAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Salud y Medicación',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 28, color: AppColors.primaryTeal),
            tooltip: 'Exportar Reporte Médico PDF',
            onPressed: () => _generarPDF(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildPillTab(index: 0, label: 'Tomas de Hoy', icon: Icons.medication_rounded),
                _buildPillTab(index: 1, label: 'Mi Botiquín', icon: Icons.inventory_2_outlined),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _vistaSeleccionada,
        children: [
          // ── VISTA 0: TOMAS Y MEDICINAS DE HOY ──
          _buildTomasView(medicamentos, tratamientos),

          // ── VISTA 1: BOTIQUÍN E INVENTARIO ──
          BotiquinInventarioTab(
            medicamentos: medicamentos,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirAdd(context),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 26),
        label: const Text('Nueva Medicina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
