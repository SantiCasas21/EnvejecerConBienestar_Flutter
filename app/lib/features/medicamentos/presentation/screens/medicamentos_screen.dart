import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/pdf_report_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

    await PdfReportService.generarYCompartirReporte(
      usuario: user,
      perfil: perfil,
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
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              Icon(icon, size: 18, color: activo ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: activo ? Colors.white : AppColors.textSecondary,
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
                Text(
                  'Sugerencias Frecuentes',
                  style: AppTypography.subtitulo().copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                Text(
                  'Tus Medicamentos (${medicamentos.length})',
                  style: AppTypography.subtitulo().copyWith(fontSize: 19, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
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
