import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/whatsapp_report_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/historial_toma_model.dart';
import '../../data/models/resumen_adherencia_model.dart';
import '../providers/historial_provider.dart';
import '../widgets/selector_fecha_carousel.dart';
import '../widgets/tarjeta_adherencia_diaria.dart';
import '../widgets/tarjeta_toma_historial.dart';
import '../widgets/seccion_habitos_dia.dart';
import '../widgets/vista_graficas_reporte.dart';

/// Pantalla accesible de consulta histórica de tomas de medicamentos y hábitos diarios
class HistorialScreen extends ConsumerStatefulWidget {
  final int? pacienteId;
  final String? fechaInicial;
  final int tabInicial;

  const HistorialScreen({
    super.key,
    this.pacienteId,
    this.fechaInicial,
    this.tabInicial = 0,
  });

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  late DateTime _fechaSeleccionada;
  late int _tabSeleccionada;

  @override
  void initState() {
    super.initState();
    _tabSeleccionada = widget.tabInicial;
    if (widget.fechaInicial != null && widget.fechaInicial!.isNotEmpty) {
      try {
        _fechaSeleccionada = DateTime.parse(widget.fechaInicial!);
      } catch (_) {
        _fechaSeleccionada = DateTime.now();
      }
    } else {
      _fechaSeleccionada = DateTime.now();
    }
  }

  String _formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatFechaAmigable(DateTime dt) {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    if (dt.year == hoy.year && dt.month == hoy.month && dt.day == hoy.day) {
      return 'Hoy (${dt.day}/${dt.month}/${dt.year})';
    } else if (dt.year == ayer.year && dt.month == ayer.month && dt.day == ayer.day) {
      return 'Ayer (${dt.day}/${dt.month}/${dt.year})';
    }

    const meses = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${meses[dt.month]} de ${dt.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _abrirSelectorCalendario() async {
    final DateTime now = DateTime.now();
    final DateTime minDate = DateTime(2023, 1, 1);
    final DateTime maxDate = now.add(const Duration(days: 30));

    DateTime initial = _fechaSeleccionada;
    if (initial.isBefore(minDate)) initial = minDate;
    if (initial.isAfter(maxDate)) initial = maxDate;

    final seleccion = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: maxDate,
      locale: const Locale('es', 'CO'),
      helpText: 'SELECCIONE CUALQUIER FECHA',
      cancelText: 'CANCELAR',
      confirmText: 'CONSULTAR DÍA',
      fieldLabelText: 'Fecha',
      fieldHintText: 'dd/mm/aaaa',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (seleccion != null) {
      setState(() {
        _fechaSeleccionada = seleccion;
        _tabSeleccionada = 0; // Mostrar de inmediato la vista detallada del día seleccionado
      });
    }
  }

  void _mostrarDialogoReporteDiario({
    required List<HistorialTomaModel> tomas,
    required List<HabitoHistorialModel> habitos,
    required double adherencia,
  }) {
    HapticFeedback.lightImpact();
    final authUser = ref.read(authNotifierProvider).user;
    final nombre = authUser?.nombre ?? 'Amigo/a';
    final fechaTexto = _formatFechaAmigable(_fechaSeleccionada);

    final mensaje = WhatsAppReportService.construirMensajeReporteDiario(
      nombrePaciente: nombre,
      fechaTexto: fechaTexto,
      adherencia: adherencia,
      tomas: tomas,
      habitos: habitos,
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.description_rounded, color: Color(0xFF16A34A), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reporte del Día',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            fechaTexto,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 26, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        mensaje,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mensaje));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '📋 Reporte del día copiado al portapapeles.',
                                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: AppColors.primaryTeal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primaryTeal),
                        label: const Text(
                          'Copiar',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await WhatsAppReportService.compartirReporteDiarioPorWhatsApp(
                            nombrePaciente: nombre,
                            fechaTexto: fechaTexto,
                            adherencia: adherencia,
                            tomas: tomas,
                            habitos: habitos,
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoDiaVacio() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 38,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin registros en esta fecha',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para el ${_formatFechaAmigable(_fechaSeleccionada)} no se encontraron tomas de medicamentos ni hábitos guardados.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _abrirSelectorCalendario,
                  icon: const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primaryTeal),
                  label: const Text(
                    'Elegir otra fecha',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _fechaSeleccionada = DateTime.now();
                    });
                  },
                  icon: const Icon(Icons.today_rounded, size: 20, color: Colors.white),
                  label: const Text(
                    'Volver a Hoy',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonReporteDiario({
    required List<HistorialTomaModel> tomas,
    required List<HabitoHistorialModel> habitos,
    required double adherencia,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _mostrarDialogoReporteDiario(
          tomas: tomas,
          habitos: habitos,
          adherencia: adherencia,
        ),
        icon: const Icon(Icons.assignment_outlined, size: 22, color: AppColors.primaryTeal),
        label: const Text(
          '📋 Ver / Compartir Reporte Diario',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryTeal,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primaryTeal, width: 1.6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tomasAsync = ref.watch(historialTomasProvider);
    final resumenAsync = ref.watch(resumenAdherenciaProvider);
    final habitosAsync = ref.watch(historialHabitosProvider);

    final isoSeleccionada = _formatIsoDate(_fechaSeleccionada);

    // Filtrar tomas para la fecha seleccionada
    final tomasDelDia = tomasAsync.value?.where((t) => t.fecha == isoSeleccionada).toList() ?? [];

    // Filtrar hábitos para la fecha seleccionada
    final habitosDelDia = habitosAsync.value?.where((h) => h.fecha == isoSeleccionada).toList() ?? [];

    // Calcular adherencia de este día desde el resumen o calculada al vuelo
    final resumen = resumenAsync.value;
    CumplimientoDiarioModel? cumplimientoHoy;
    if (resumen != null) {
      for (final c in resumen.cumplimientoDiario) {
        if (c.fecha == isoSeleccionada) {
          cumplimientoHoy = c;
          break;
        }
      }
    }

    double porcentajeDia = 0.0;
    int esperadas = 0;
    int tomadas = 0;
    int pospuestas = 0;
    int omitidas = 0;

    if (cumplimientoHoy != null) {
      porcentajeDia = cumplimientoHoy.porcentaje;
      esperadas = cumplimientoHoy.esperadas;
      tomadas = cumplimientoHoy.tomadas;
      pospuestas = cumplimientoHoy.pospuestas;
      omitidas = cumplimientoHoy.omitidas;
    } else if (tomasDelDia.isNotEmpty) {
      esperadas = tomasDelDia.length;
      tomadas = tomasDelDia.where((t) => t.fueTomada).length;
      pospuestas = tomasDelDia.where((t) => t.fuePospuesta).length;
      omitidas = tomasDelDia.where((t) => t.fueOmitida).length;
      porcentajeDia = esperadas > 0 ? (tomadas / esperadas) * 100 : 0.0;
    }

    final String tituloPantalla = widget.pacienteId != null
        ? 'Historial del Paciente'
        : 'Historial y Hábitos';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          tituloPantalla,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28, color: Colors.white),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 26, color: Colors.white),
            tooltip: 'Buscar en calendario',
            onPressed: _abrirSelectorCalendario,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Selector de Pestañas Superior: Diario vs Gráficas y Reporte ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBotonPestana(
                    index: 0,
                    icono: Icons.calendar_today_rounded,
                    titulo: 'Registro Diario',
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildBotonPestana(
                    index: 1,
                    icono: Icons.bar_chart_rounded,
                    titulo: 'Gráficas y Reporte',
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido de la pestaña activa ──
          Expanded(
            child: _tabSeleccionada == 1
                ? VistaGraficasReporte(pacienteId: widget.pacienteId)
                : RefreshIndicator(
                    color: AppColors.primaryTeal,
                    onRefresh: () async {
                      ref.read(historialTomasProvider.notifier).cargarTomas(pacienteId: widget.pacienteId);
                      ref.read(resumenAdherenciaProvider.notifier).cargarResumen(pacienteId: widget.pacienteId);
                      ref.read(historialHabitosProvider.notifier).cargarHabitos(pacienteId: widget.pacienteId);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Selector Semanal de 7 Días (Lunes a Domingo)
                          SelectorSemanalWidget(
                            selectedDate: _fechaSeleccionada,
                            cumplimientos: resumen?.cumplimientoDiario ?? [],
                            onDateSelected: (nuevaFecha) {
                              setState(() {
                                _fechaSeleccionada = nuevaFecha;
                              });
                            },
                          ),

                          const SizedBox(height: 8),

                          if (!_isSameDay(_fechaSeleccionada, DateTime.now()))
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.history_rounded, size: 22, color: AppColors.primaryTeal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Historial: ${_formatFechaAmigable(_fechaSeleccionada)}',
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _fechaSeleccionada = DateTime.now();
                                      });
                                    },
                                    icon: const Icon(Icons.today_rounded, size: 18, color: AppColors.primaryTeal),
                                    label: const Text(
                                      'Ir a Hoy',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Estado vacío accesible si el día no tiene registros de tomas ni de hábitos
                          if (tomasDelDia.isEmpty && habitosDelDia.isEmpty)
                            _buildEstadoDiaVacio()
                          else ...[
                            // Tarjeta Resumen Emocional y Adherencia del Día
                            TarjetaAdherenciaDiaria(
                              porcentaje: porcentajeDia,
                              tomadas: tomadas,
                              pospuestas: pospuestas,
                              omitidas: omitidas,
                              totalEsperadas: esperadas,
                              fechaFormateada: _formatFechaAmigable(_fechaSeleccionada),
                            ),

                            // Botón accesible de reporte diario
                            _buildBotonReporteDiario(
                              tomas: tomasDelDia,
                              habitos: habitosDelDia,
                              adherencia: porcentajeDia,
                            ),

                            const SizedBox(height: 10),

                            // Sección: Tomas de Medicamentos del Día
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.medication_rounded, size: 22, color: AppColors.primaryTeal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tomas de este Día (${tomasDelDia.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (tomasDelDia.isEmpty)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle_outline_rounded, size: 28, color: AppColors.textSecondary),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No hay registros de medicamentos en esta fecha.',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 15,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...tomasDelDia.map((t) => TarjetaTomaHistorial(toma: t)),

                            const SizedBox(height: 12),

                            // Sección: Metas y Hábitos de Bienestar
                            SeccionHabitosDia(habitos: habitosDelDia),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPestana({
    required int index,
    required IconData icono,
    required String titulo,
  }) {
    final bool activa = _tabSeleccionada == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _tabSeleccionada = index;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activa ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: activa
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 18,
              color: activa ? AppColors.primaryTeal : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
                  color: activa ? AppColors.primaryTeal : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
