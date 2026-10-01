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
  final int? pacienteId;
  final Future<void> Function(dynamic medId, int cantidad, String medNombre)?
      onReabastecer;

  const BotiquinInventarioTab({
    super.key,
    required this.medicamentos,
    this.pacienteId,
    this.onReabastecer,
  });

  @override
  ConsumerState<BotiquinInventarioTab> createState() =>
      _BotiquinInventarioTabState();
}

class _BotiquinInventarioTabState extends ConsumerState<BotiquinInventarioTab> {
  String _filtro = 'todos'; // 'todos', 'alerta', 'agotados'

  void _reabastecer(dynamic medId, int cantidad, String medNombre) async {
    if (widget.onReabastecer != null) {
      await widget.onReabastecer!(medId, cantidad, medNombre);
    } else {
      await ref
          .read(medicamentosNotifierProvider.notifier)
          .reabastecerStock(medId, cantidad);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📦 ¡Se agregaron +$cantidad pastillas a $medNombre!',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: AppColors.healthGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _ajustarManual(Medicamento med) async {
    final controller =
        TextEditingController(text: '${med.cantidadRestante ?? 30}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded,
                color: AppColors.primaryTeal, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ajustar inventario de ${med.nombre}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el número total de pastillas disponibles actualmente en la caja o blíster:',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
              decoration: InputDecoration(
                labelText: 'Pastillas en existencia',
                prefixIcon: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primaryTeal),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, n);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final actual = med.cantidadRestante ?? 0;
      final diff = result - actual;
      if (diff != 0) {
        if (widget.onReabastecer != null) {
          await widget.onReabastecer!(med.id, diff, med.nombre);
        } else {
          await ref
              .read(medicamentosNotifierProvider.notifier)
              .reabastecerStock(med.id, diff);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📦 Inventario de ${med.nombre} actualizado a $result pastillas',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: AppColors.healthGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
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
          content: const Text(
              'Configura un teléfono de contacto en tu Perfil para pedir a domicilio.'),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            final cant = med.cantidadRestante ?? 0;
            final dias = med.diasAutonomia;
            final esAgotado = cant <= 0;
            final esBajo = !esAgotado && (cant <= (med.umbralAlerta ?? 5) || dias <= 7);

            final Color stockColor;
            final String badgeTexto;
            if (esAgotado) {
              stockColor = const Color(0xFFE11D48); // Rojo
              badgeTexto = '🔴 Agotado';
            } else if (esBajo) {
              stockColor = const Color(0xFFF59E0B); // Ámbar
              badgeTexto = '⚠️ Stock Bajo (≤ 5)';
            } else {
              stockColor = const Color(0xFF16A34A); // Verde
              badgeTexto = '🟢 Stock Óptimo';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: stockColor.withValues(alpha: 0.4), width: 1.5),
              ),
              color: AppColors.cardBackground,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila cabecera del medicamento estilo Blíster/Caja
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: stockColor.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              med.icono.isNotEmpty ? med.icono : '💊',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${med.nombre} ${med.miligramos != null && med.miligramos!.isNotEmpty ? "${med.miligramos}mg" : ""}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '⏰ Frecuencia: Cada ${med.frecuencia ?? 8} horas',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: stockColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            badgeTexto,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: stockColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Barra y texto de stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$cant pastillas disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: stockColor,
                          ),
                        ),
                        Text(
                          esAgotado
                              ? 'Sin autonomía'
                              : 'Te quedan ~$dias días',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: esAgotado ? stockColor : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (cant / 30).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Botones de Reabastecimiento interactivo (Accesibles para Paciente y Cuidador)
                    const Text(
                      'Reabastecer botiquín:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _reabastecer(med.id, 10, med.nombre),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: AppColors.primaryTeal),
                            ),
                            child: const Text(
                              '+10 pastillas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.primaryTeal),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _reabastecer(med.id, 30, med.nombre),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              '+30 (1 Caja)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primaryDark),
                          tooltip: 'Ajustar número exacto',
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(46, 46),
                          ),
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
