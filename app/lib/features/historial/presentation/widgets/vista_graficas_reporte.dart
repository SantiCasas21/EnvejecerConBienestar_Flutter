import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/pdf_report_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../medicamentos/presentation/providers/medicamentos_provider.dart';
import '../../../perfil/presentation/providers/perfil_provider.dart';
import '../../../medicamentos/presentation/providers/tratamientos_provider.dart';
import '../../../home/presentation/providers/metas_provider.dart';
import '../../data/models/resumen_adherencia_model.dart';
import '../providers/historial_provider.dart';
import 'adherencia_donut_widget.dart';
import 'grafica_barras_semanales_widget.dart';
import 'preview_reporte_dialog.dart';

/// Pestaña interactiva de Gráficas y Reportes (Módulo 8)
class VistaGraficasReporte extends ConsumerWidget {
  final int? pacienteId;

  const VistaGraficasReporte({
    super.key,
    this.pacienteId,
  });

  void _abrirPreviewWhatsApp(BuildContext context, WidgetRef ref, ResumenAdherenciaModel resumen, String periodoNombre) {
    HapticFeedback.lightImpact();
    final authUser = ref.read(authNotifierProvider).user;
    final nombrePaciente = authUser?.nombre ?? 'Amigo/a';

    showDialog(
      context: context,
      builder: (_) => PreviewReporteDialog(
        nombrePaciente: nombrePaciente,
        resumen: resumen,
        periodoNombre: periodoNombre,
      ),
    );
  }

  void _exportarPdf(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final authUser = ref.read(authNotifierProvider).user;
    if (authUser == null) return;

    final perfil = ref.read(perfilNotifierProvider).value;
    final medicamentos = ref.read(medicamentosNotifierProvider).value ?? [];
    final tratamientos = ref.read(tratamientosNotifierProvider).value ?? [];
    final metas = ref.read(metasNotifierProvider).value ?? [];

    try {
      await PdfReportService.generarYCompartirReporte(
        usuario: authUser,
        perfil: perfil,
        tratamientos: tratamientos,
        medicamentos: medicamentos,
        metas: metas,
        incluirDocumento: false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '📄 Expediente PDF generado y listo para compartir o imprimir.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No se pudo generar el PDF en este momento.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.emergencyRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoEstadisticasProvider);
    final resumenAsync = ref.watch(resumenAdherenciaProvider);

    final esSemanal = periodo == PeriodoEstadisticas.semanal;
    final periodoTexto = esSemanal ? 'Últimos 7 Días' : 'Últimos 30 Días';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Selector Temporal: Semanal vs Mensual ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBotonPeriodo(
                    ref: ref,
                    activo: esSemanal,
                    label: '🗓️ Últimos 7 Días',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(periodoEstadisticasProvider.notifier).state = PeriodoEstadisticas.semanal;
                      ref.read(resumenAdherenciaProvider.notifier).cargarResumen(dias: 7, pacienteId: pacienteId);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildBotonPeriodo(
                    ref: ref,
                    activo: !esSemanal,
                    label: '📆 Últimos 30 Días',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(periodoEstadisticasProvider.notifier).state = PeriodoEstadisticas.mensual;
                      ref.read(resumenAdherenciaProvider.notifier).cargarResumen(dias: 30, pacienteId: pacienteId);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Estado de Carga / Error / Datos del Resumen ──
          resumenAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'No pudimos cargar las estadísticas en este momento: $err',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            data: (resumen) {
              if (resumen == null) {
                return const Center(child: Text('No hay datos disponibles.'));
              }

              // Calcular promedio de hábitos para el KPI
              double promedioHabitos = 0.0;
              if (resumen.resumenHabitos.isNotEmpty) {
                final suma = resumen.resumenHabitos.fold(0.0, (acc, h) => acc + h.porcentaje);
                promedioHabitos = suma / resumen.resumenHabitos.length;
              } else {
                promedioHabitos = 85.0; // fallback
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Donut de Adherencia Global
                  AdherenciaDonutWidget(
                    resumen: resumen,
                    periodoTexto: periodoTexto,
                  ),
                  const SizedBox(height: 14),

                  // 2. Tarjetas KPI de Resumen Rápido (3 columnas)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTarjetaKpi(
                          icono: '💊',
                          valor: '${resumen.totalTomadas}',
                          subtitulo: 'de ${resumen.totalEsperadas} tomas',
                          colorFondo: const Color(0xFFF0FDFA),
                          colorTexto: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTarjetaKpi(
                          icono: '💧',
                          valor: '${promedioHabitos.toInt()}%',
                          subtitulo: 'hábitos cumplidos',
                          colorFondo: const Color(0xFFE0F2FE),
                          colorTexto: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTarjetaKpi(
                          icono: '🔥',
                          valor: '${resumen.racha?.rachaActual ?? 0}',
                          subtitulo: 'días de racha',
                          colorFondo: const Color(0xFFFFF7ED),
                          colorTexto: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Gráfica de Barras Diarias
                  GraficaBarrasSemanalesWidget(
                    dias: resumen.cumplimientoDiario,
                  ),
                  const SizedBox(height: 16),

                  // 4. Desglose de Medicamentos
                  _buildSeccionMedicamentos(resumen.medicamentosAdherencia),
                  const SizedBox(height: 16),

                  // 5. Desglose de Hábitos de Bienestar
                  if (resumen.resumenHabitos.isNotEmpty) ...[
                    _buildSeccionHabitos(resumen.resumenHabitos),
                    const SizedBox(height: 18),
                  ],

                  // 6. Botones de Acción Prominentes
                  // Botón WhatsApp
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirPreviewWhatsApp(context, ref, resumen, periodoTexto),
                      icon: const Icon(Icons.share_rounded, size: 22),
                      label: const Text(
                        'Compartir Resumen por WhatsApp',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón PDF Clínico
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _exportarPdf(context, ref),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: const Text(
                        'Descargar Expediente Clínico (PDF)',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPeriodo({
    required WidgetRef ref,
    required bool activo,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
            color: activo ? AppColors.primaryTeal : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaKpi({
    required String icono,
    required String valor,
    required String subtitulo,
    required Color colorFondo,
    required Color colorTexto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorTexto.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(icono, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colorTexto,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionMedicamentos(List<MedicamentoAdherenciaModel> medicamentos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.medication_rounded, color: AppColors.primaryTeal, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cumplimiento por Medicamento',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (medicamentos.isEmpty)
            const Text(
              'No hay tomas registradas en este periodo.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary),
            )
          else
            ...medicamentos.map((med) {
              final pct = med.porcentaje.clamp(0.0, 100.0);
              final esBajoStock = med.cantidadRestante != null && med.cantidadRestante! <= 5;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(med.icono, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            med.nombre,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${pct.toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pct >= 80 ? AppColors.successGreen : (pct >= 50 ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${med.tomadas} de ${med.esperadas} tomas realizadas',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (esBajoStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '⚠️ Quedan ${med.cantidadRestante}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
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
      ),
    );
  }

  Widget _buildSeccionHabitos(List<HabitoResumenModel> habitos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.self_improvement_rounded, color: AppColors.primaryTeal, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Constancia en Hábitos de Vida',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...habitos.map((hab) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text(hab.icono, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hab.nombre,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${hab.cumplidos} de ${hab.totalDias} días logrados',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${hab.porcentaje.toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: hab.porcentaje >= 80 ? AppColors.successGreen : const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
