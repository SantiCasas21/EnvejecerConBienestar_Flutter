import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/call_service.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../data/models/medicamento_model.dart';
import '../providers/medicamentos_provider.dart';

class BotiquinInventarioTab extends ConsumerStatefulWidget {
  final List<Medicamento> medicamentos;

  const BotiquinInventarioTab({super.key, required this.medicamentos});

  @override
  ConsumerState<BotiquinInventarioTab> createState() => _BotiquinInventarioTabState();
}

class _BotiquinInventarioTabState extends ConsumerState<BotiquinInventarioTab> {
  String _filtro = 'todos'; // 'todos', 'alerta', 'agotados'

  void _reabastecer(dynamic medId, int cantidad, String medNombre) async {
    await ref.read(medicamentosNotifierProvider.notifier).reabastecerStock(medId, cantidad);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📦 +$cantidad pastillas agregadas a $medNombre', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.healthGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _ajustarManual(Medicamento med) async {
    final controller = TextEditingController(text: '${med.cantidadRestante ?? 30}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ajustar inventario de ${med.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa la cantidad exacta de pastillas en la caja actualmente:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Pastillas en caja',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, n);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      final actual = med.cantidadRestante ?? 0;
      final diff = result - actual;
      if (diff != 0) {
        await ref.read(medicamentosNotifierProvider.notifier).reabastecerStock(med.id, diff);
      }
    }
  }

  void _pedirFarmacia(BuildContext context) async {
    final perfil = ref.read(perfilNotifierProvider).value;
    final tel = perfil?.telefono ?? perfil?.contactoEmergenciaTelefono;

    if (tel != null && tel.isNotEmpty) {
      await CallService.realizarLlamada(tel);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configura un teléfono de contacto en tu Perfil para pedir a domicilio.'),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = widget.medicamentos;
    final totalMeds = meds.length;
    final agotados = meds.where((m) => m.nivelStock == 'agotado').length;
    final enAlerta = meds.where((m) => m.nivelStock == 'bajo' || m.nivelStock == 'critico').length;
    final optimos = totalMeds - agotados - enAlerta;

    List<Medicamento> filtrados = meds;
    if (_filtro == 'alerta') {
      filtrados = meds.where((m) => m.nivelStock == 'bajo' || m.nivelStock == 'critico').toList();
    } else if (_filtro == 'agotados') {
      filtrados = meds.where((m) => m.nivelStock == 'agotado').toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ── Tarjeta Resumen del Botiquín ──
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          color: AppColors.cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('📦', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Mi Botiquín',
                          style: AppTypography.subtitulo().copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: AppColors.primaryTeal),
                      label: const Text('Farmacia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryTeal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _pedirFarmacia(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contadores con Semáforo
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('$optimos', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                            const SizedBox(height: 2),
                            const Text('Stock óptimo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('$enAlerta', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                            const SizedBox(height: 2),
                            const Text('Por reponer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('$agotados', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFBE123C))),
                            const SizedBox(height: 2),
                            const Text('Agotados', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFBE123C))),
                          ],
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

        // ── Filtros ──
        Row(
          children: [
            FilterChip(
              selected: _filtro == 'todos',
              label: Text('Todos ($totalMeds)'),
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primaryTeal,
              onSelected: (_) => setState(() => _filtro = 'todos'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: _filtro == 'alerta',
              label: Text('⚠️ Por reponer ($enAlerta)'),
              selectedColor: Colors.amber.shade100,
              checkmarkColor: Colors.amber.shade900,
              onSelected: (_) => setState(() => _filtro = 'alerta'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: _filtro == 'agotados',
              label: Text('❌ Agotados ($agotados)'),
              selectedColor: Colors.red.shade100,
              checkmarkColor: AppColors.emergencyRed,
              onSelected: (_) => setState(() => _filtro = 'agotados'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Lista de Medicamentos con Control de Stock ──
        if (filtrados.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No hay medicamentos en esta categoría de inventario.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          ),
        ] else ...[
          ...filtrados.map((med) {
            final stockColor = med.colorStock;
            final cant = med.cantidadRestante ?? 0;
            final dias = med.diasAutonomia;

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: stockColor.withValues(alpha: 0.35), width: 1.5),
              ),
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila cabecera del medicamento
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(med.icono, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${med.nombre} ${med.miligramos != null ? "${med.miligramos}mg" : ""}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: stockColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            med.nivelStock.toUpperCase(),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stockColor),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Barra y texto de stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$cant pastillas restantes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stockColor),
                        ),
                        Text(
                          '~ $dias días de autonomía',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (cant / 30).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Botones de Reabastecimiento Senior en 1-Tap
                    const Text(
                      'Reabastecer stock rápido:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _reabastecer(med.id, 10, med.nombre),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppColors.primaryTeal),
                            ),
                            child: const Text('+10 pastillas', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _reabastecer(med.id, 30, med.nombre),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('+30 (1 Caja)', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
                          tooltip: 'Ajustar número exacto',
                          onPressed: () => _ajustarManual(med),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
