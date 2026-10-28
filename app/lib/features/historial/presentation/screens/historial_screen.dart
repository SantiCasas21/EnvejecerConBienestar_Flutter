import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/historial_provider.dart';
import '../widgets/selector_fecha_carousel.dart';
import '../widgets/tarjeta_adherencia_diaria.dart';
import '../widgets/tarjeta_toma_historial.dart';
import '../widgets/seccion_habitos_dia.dart';

/// Pantalla accesible de consulta histórica de tomas de medicamentos y hábitos diarios
class HistorialScreen extends ConsumerStatefulWidget {
  final int? pacienteId;
  final String? fechaInicial;

  const HistorialScreen({
    super.key,
    this.pacienteId,
    this.fechaInicial,
  });

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
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

  Future<void> _abrirSelectorCalendario() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 180)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es', 'CO'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
      });
    }
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
    final cumplimientoHoy = resumen?.cumplimientoDiario.firstWhere(
      (c) => c.fecha == isoSeleccionada,
      orElse: () => null as dynamic,
    );

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
      body: RefreshIndicator(
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
              const SizedBox(height: 12),

              // Carrusel Selector de Días
              SelectorFechaCarousel(
                selectedDate: _fechaSeleccionada,
                cumplimientos: resumen?.cumplimientoDiario ?? [],
                onDateSelected: (nuevaFecha) {
                  setState(() {
                    _fechaSeleccionada = nuevaFecha;
                  });
                },
              ),

              const SizedBox(height: 8),

              // Tarjeta Resumen Emocional y Adherencia del Día
              TarjetaAdherenciaDiaria(
                porcentaje: porcentajeDia,
                tomadas: tomadas,
                pospuestas: pospuestas,
                omitidas: omitidas,
                totalEsperadas: esperadas,
                fechaFormateada: _formatFechaAmigable(_fechaSeleccionada),
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
          ),
        ),
      ),
    );
  }
}
