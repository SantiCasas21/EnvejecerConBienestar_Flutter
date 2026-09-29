import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/utils/notification_service.dart';
import '../providers/medicamentos_provider.dart';

class MedicamentoDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const MedicamentoDetailScreen({super.key, required this.id});

  @override
  ConsumerState<MedicamentoDetailScreen> createState() => _MedicamentoDetailScreenState();
}

class _MedicamentoDetailScreenState extends ConsumerState<MedicamentoDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _guardando = false;

  final _nombreController = TextEditingController();
  final _dosisController = TextEditingController();
  final _frecuenciaController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _notasController = TextEditingController();
  TimeOfDay _horaAlarma = const TimeOfDay(hour: 8, minute: 0);

  @override
  void dispose() {
    _nombreController.dispose();
    _dosisController.dispose();
    _frecuenciaController.dispose();
    _cantidadController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _cargarDatos(dynamic med) {
    if (!_isEditing) {
      _nombreController.text = med.nombre;
      _dosisController.text = med.miligramos ?? '';
      _frecuenciaController.text = med.frecuencia?.toString() ?? '8';
      _cantidadController.text = med.cantidadRestante?.toString() ?? '30';
      _notasController.text = med.notas ?? '';

      if (med.horaAlarma != null && med.horaAlarma!.isNotEmpty) {
        final partes = med.horaAlarma!.split(':');
        if (partes.length >= 2) {
          _horaAlarma = TimeOfDay(
            hour: int.tryParse(partes[0]) ?? 8,
            minute: int.tryParse(partes[1]) ?? 0,
          );
        }
      }
    }
  }

  void _guardar(int idNum) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _guardando = true);
      final horaStr = '${_horaAlarma.hour.toString().padLeft(2, '0')}:${_horaAlarma.minute.toString().padLeft(2, '0')}:00';
      
      final data = {
        'nombre': _nombreController.text.trim(),
        'miligramos': _dosisController.text.trim(),
        'frecuencia': int.tryParse(_frecuenciaController.text.trim()) ?? 8,
        'cantidad_restante': int.tryParse(_cantidadController.text.trim()) ?? 30,
        'hora_alarma': horaStr,
        'notas': _notasController.text.trim(),
      };

      try {
        await ref.read(medicamentosNotifierProvider.notifier).updateMedicamento(idNum, data);
        setState(() => _isEditing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Medicamento actualizado correctamente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.healthGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: AppColors.emergencyRed),
          );
        }
      } finally {
        if (mounted) setState(() => _guardando = false);
      }
    }
  }

  void _eliminar(int idNum, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar $nombre?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este tratamiento? Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 17, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
            child: const Text('Sí, eliminar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(medicamentosNotifierProvider.notifier).deleteMedicamento(idNum);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicamentosAsync = ref.watch(medicamentosNotifierProvider);
    final idNum = int.tryParse(widget.id) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle de Medicina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30, color: AppColors.primaryTeal),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_note_rounded, size: 32, color: AppColors.primaryTeal),
            tooltip: _isEditing ? 'Cancelar edición' : 'Editar medicina',
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: medicamentosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
        error: (err, _) => Center(child: Text('Error: $err', style: AppTypography.cuerpo())),
        data: (list) {
          final med = list.where((m) => m.id.toString() == widget.id).firstOrNull;

          if (med == null) {
            return const Center(child: Text('Medicamento no encontrado', style: TextStyle(fontSize: 18)));
          }

          _cargarDatos(med);
          final tomado = med.estaTomado ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── AVATAR CIRCULAR Y ESTADO DEL MEDICAMENTO ──
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: tomado ? AppColors.completedLight : AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tomado ? AppColors.completed : AppColors.primaryTeal,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Text(med.icono, style: const TextStyle(fontSize: 48)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chip de estado
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: tomado ? AppColors.completedLight : AppColors.emergencyRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tomado ? AppColors.completed : AppColors.emergencyRed,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        tomado ? '✅ Tomado hoy' : '⏳ Dosis pendiente hoy',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tomado ? AppColors.primaryDark : AppColors.emergencyRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── INFORMACIÓN GENERAL DEL TRATAMIENTO ──
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💊', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text(
                                'Datos del Medicamento',
                                style: AppTypography.subtitulo().copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, thickness: 1.5, color: AppColors.border),

                          // Nombre
                          if (_isEditing)
                            TextFormField(
                              controller: _nombreController,
                              style: AppTypography.cuerpo(),
                              decoration: const InputDecoration(labelText: 'Nombre de la medicina'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                            )
                          else
                            _buildItemVisual('Nombre', med.nombre, Icons.medication_rounded),
                          const SizedBox(height: 14),

                          // Dosis y Frecuencia
                          if (_isEditing) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dosisController,
                                    style: AppTypography.cuerpo(),
                                    decoration: const InputDecoration(labelText: 'Dosis (mg)', hintText: 'Ej: 500'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _frecuenciaController,
                                    keyboardType: TextInputType.number,
                                    style: AppTypography.cuerpo(),
                                    decoration: const InputDecoration(labelText: 'Frecuencia (horas)', hintText: 'Ej: 8'),
                                    validator: (v) {
                                      if (v != null && v.isNotEmpty) {
                                        final f = int.tryParse(v);
                                        if (f == null || f < 1 || f > 72) return 'Entre 1 y 72h';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(child: _buildItemVisual('Dosis', '${med.miligramos ?? "-"} mg', Icons.scale_rounded)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildItemVisual('Frecuencia', 'Cada ${med.frecuencia ?? 24} horas', Icons.repeat_rounded)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Stock / Cantidad de pastillas
                          if (_isEditing)
                            TextFormField(
                              controller: _cantidadController,
                              keyboardType: TextInputType.number,
                              style: AppTypography.cuerpo(),
                              decoration: const InputDecoration(
                                labelText: 'Pastillas en caja (Inventario)',
                                hintText: 'Ej: 30',
                                prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.primaryTeal),
                              ),
                            )
                          else
                            _buildItemVisual(
                              'Inventario Disponible',
                              med.textoInventario,
                              Icons.inventory_2_outlined,
                              valorColor: med.alertaInventario ? AppColors.emergencyRed : null,
                              destacado: med.alertaInventario,
                            ),
                          const SizedBox(height: 14),

                          // Hora de inicio / primera toma
                          if (_isEditing) ...[
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _horaAlarma);
                                if (picked != null) setState(() => _horaAlarma = picked);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, color: AppColors.primaryTeal, size: 26),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Hora de la primera toma: ${_horaAlarma.hour.toString().padLeft(2, '0')}:${_horaAlarma.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Icon(Icons.edit, size: 18, color: AppColors.primaryTeal),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            _buildItemVisual('Hora de Primera Alarma', med.horaAlarma12, Icons.alarm_rounded),
                          ],

                          if (med.notas != null && med.notas!.isNotEmpty || _isEditing) ...[
                            const SizedBox(height: 14),
                            if (_isEditing)
                              TextFormField(
                                controller: _notasController,
                                maxLines: 2,
                                style: AppTypography.cuerpo(),
                                decoration: const InputDecoration(labelText: 'Notas / Instrucciones (ej: con alimentos)'),
                              )
                            else
                              _buildItemVisual('Instrucciones / Notas', med.notas!, Icons.note_alt_outlined),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── TARJETA: HORARIO DIARIO DE TOMAS CALCULADO ──
                  if (!_isEditing) ...[
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🕐', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Horario de Tomas Hoy',
                                        style: AppTypography.subtitulo().copyWith(
                                          color: AppColors.primaryDark,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Cada ${med.frecuencia ?? 24} horas · ${med.tomasPorDia} ${med.tomasPorDia == 1 ? "toma" : "tomas"} al día',
                                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, thickness: 1.5, color: AppColors.border),
                            Text(
                              med.textoHorario,
                              style: AppTypography.cuerpo().copyWith(
                                fontSize: 17,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primaryTeal, size: 22),
                                label: const Text(
                                  'Probar Alarma Sonora',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  await NotificationService.probarAlarmaSonora();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🔔 Probando alarma sonora para ${med.nombre}'),
                                        backgroundColor: AppColors.healthGreen,
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── BOTONES DE ACCIÓN (EDICIÓN / ELIMINACIÓN) ──
                  if (_isEditing) ...[
                    SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _guardando ? null : () => _guardar(idNum),
                        icon: _guardando
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 26),
                        label: const Text('Guardar Cambios', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.healthGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _eliminar(idNum, med.nombre),
                      icon: const Icon(Icons.delete_forever_rounded, color: AppColors.emergencyRed, size: 24),
                      label: const Text('Eliminar Medicina', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.emergencyRed)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        side: const BorderSide(color: AppColors.emergencyRed, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemVisual(String titulo, String valor, IconData icono, {Color? valorColor, bool destacado = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: destacado ? AppColors.emergencyRed : AppColors.border, width: destacado ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppColors.primaryTeal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: valorColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
