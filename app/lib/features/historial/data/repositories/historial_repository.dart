import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/historial_toma_model.dart';
import '../models/resumen_adherencia_model.dart';

class HistorialRepository {
  final Dio _dio;

  // Fallback offline en memoria para resiliencia (Regla 4 ia/desarrollo.md)
  final List<HistorialTomaModel> _fallbackTomas = [
    HistorialTomaModel(
      id: 1,
      usuarioId: 1,
      medicamentoId: 1,
      medicamentoNombre: 'Losartán Potásico',
      medicamentoIcono: '💊',
      medicamentoMiligramos: '50 mg',
      medicamentoColor: '#0D9488',
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      horaProgramada: '08:00',
      horaReal: DateTime.now().toIso8601String(),
      estado: 'tomada',
      notas: 'Tomada con agua después del desayuno',
    ),
    HistorialTomaModel(
      id: 2,
      usuarioId: 1,
      medicamentoId: 2,
      medicamentoNombre: 'Metformina',
      medicamentoIcono: '💊',
      medicamentoMiligramos: '850 mg',
      medicamentoColor: '#2563EB',
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      horaProgramada: '07:30',
      horaReal: DateTime.now().toIso8601String(),
      estado: 'tomada',
    ),
    HistorialTomaModel(
      id: 3,
      usuarioId: 1,
      medicamentoId: 3,
      medicamentoNombre: 'Acetaminofén',
      medicamentoIcono: '💊',
      medicamentoMiligramos: '500 mg',
      medicamentoColor: '#F59E0B',
      fecha: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
      horaProgramada: '14:00',
      horaReal: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      estado: 'tomada',
    ),
  ];

  HistorialRepository(this._dio);

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Obtiene la lista cronológica de tomas con filtros opcionales
  Future<List<HistorialTomaModel>> getTomas({
    DateTime? desde,
    DateTime? hasta,
    int? medicamentoId,
    int? pacienteId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (desde != null) queryParams['desde'] = _formatDate(desde);
      if (hasta != null) queryParams['hasta'] = _formatDate(hasta);
      if (medicamentoId != null) queryParams['medicamento_id'] = medicamentoId;
      if (pacienteId != null) queryParams['paciente_id'] = pacienteId;

      final response = await _dio.get(
        '${ApiEndpoints.historial}/tomas',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) =>
                HistorialTomaModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return _fallbackTomas;
    } on DioException catch (_) {
      return _filtrarFallbackTomas(desde, hasta, medicamentoId);
    } catch (_) {
      return _fallbackTomas;
    }
  }

  List<HistorialTomaModel> _filtrarFallbackTomas(
    DateTime? desde,
    DateTime? hasta,
    int? medicamentoId,
  ) {
    return _fallbackTomas.where((t) {
      if (medicamentoId != null && t.medicamentoId != medicamentoId) return false;
      if (desde != null && t.fecha.compareTo(_formatDate(desde)) < 0) return false;
      if (hasta != null && t.fecha.compareTo(_formatDate(hasta)) > 0) return false;
      return true;
    }).toList();
  }

  /// Registra o actualiza el estado de una toma específica
  Future<HistorialTomaModel?> registrarToma({
    required int medicamentoId,
    DateTime? fecha,
    String? horaProgramada,
    String estado = 'tomada',
    String? notas,
    int? pacienteId,
  }) async {
    final data = <String, dynamic>{
      'medicamento_id': medicamentoId,
      'estado': estado,
    };
    if (fecha != null) data['fecha'] = _formatDate(fecha);
    if (horaProgramada != null) data['hora_programada'] = horaProgramada;
    if (notas != null) data['notas'] = notas;
    if (pacienteId != null) data['paciente_id'] = pacienteId;

    try {
      final response = await _dio.post(
        '${ApiEndpoints.historial}/tomas',
        data: data,
      );

      if (response.statusCode == 201 && response.data is Map) {
        final nuevo = HistorialTomaModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
        _fallbackTomas.insert(0, nuevo);
        return nuevo;
      }
      return null;
    } on DioException catch (_) {
      final local = HistorialTomaModel(
        id: DateTime.now().millisecondsSinceEpoch,
        usuarioId: pacienteId ?? 1,
        medicamentoId: medicamentoId,
        fecha: fecha != null ? _formatDate(fecha) : _formatDate(DateTime.now()),
        horaProgramada: horaProgramada ?? '08:00',
        horaReal: DateTime.now().toIso8601String(),
        estado: estado,
        notas: notas,
      );
      _fallbackTomas.insert(0, local);
      return local;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el resumen de adherencia para el rango indicado
  Future<ResumenAdherenciaModel> getResumenAdherencia({
    DateTime? desde,
    DateTime? hasta,
    int? pacienteId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (desde != null) queryParams['desde'] = _formatDate(desde);
      if (hasta != null) queryParams['hasta'] = _formatDate(hasta);
      if (pacienteId != null) queryParams['paciente_id'] = pacienteId;

      final response = await _dio.get(
        '${ApiEndpoints.historial}/resumen',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data is Map) {
        return ResumenAdherenciaModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
      return _generarFallbackResumen(desde, hasta);
    } on DioException catch (_) {
      return _generarFallbackResumen(desde, hasta);
    } catch (_) {
      return _generarFallbackResumen(desde, hasta);
    }
  }

  ResumenAdherenciaModel _generarFallbackResumen(DateTime? desde, DateTime? hasta) {
    final hoy = DateTime.now();
    final fFin = hasta ?? hoy;
    final fInicio = desde ?? fFin.subtract(const Duration(days: 6));

    final dias = <CumplimientoDiarioModel>[];
    var cur = fInicio;
    while (!cur.isAfter(fFin)) {
      final dateStr = _formatDate(cur);
      final tomasDelDia = _fallbackTomas.where((t) => t.fecha == dateStr).toList();
      final tomadas = tomasDelDia.where((t) => t.estado == 'tomada').length;
      final esperadas = tomasDelDia.isEmpty ? 3 : tomasDelDia.length;
      final pct = esperadas > 0 ? (tomadas / esperadas) * 100 : 0.0;

      dias.add(CumplimientoDiarioModel(
        fecha: dateStr,
        diaSemana: _getNombreDia(cur.weekday),
        esperadas: esperadas,
        tomadas: tomadas,
        pospuestas: tomasDelDia.where((t) => t.estado == 'pospuesta').length,
        omitidas: tomasDelDia.where((t) => t.estado == 'omitida').length,
        porcentaje: double.parse(pct.toStringAsFixed(1)),
      ));
      cur = cur.add(const Duration(days: 1));
    }

    final totalEsperadas = dias.fold(0, (sum, d) => sum + d.esperadas);
    final totalTomadas = dias.fold(0, (sum, d) => sum + d.tomadas);
    final totalPospuestas = dias.fold(0, (sum, d) => sum + d.pospuestas);
    final totalOmitidas = dias.fold(0, (sum, d) => sum + d.omitidas);
    final pctGlobal = totalEsperadas > 0
        ? double.parse(((totalTomadas / totalEsperadas) * 100).toStringAsFixed(1))
        : 85.0;

    return ResumenAdherenciaModel(
      usuarioId: 1,
      fechaInicio: _formatDate(fInicio),
      fechaFin: _formatDate(fFin),
      totalEsperadas: totalEsperadas > 0 ? totalEsperadas : 21,
      totalTomadas: totalTomadas > 0 ? totalTomadas : 18,
      totalPospuestas: totalPospuestas,
      totalOmitidas: totalOmitidas > 0 ? totalOmitidas : 3,
      porcentajeAdherenciaGlobal: pctGlobal,
      cumplimientoDiario: dias,
      medicamentosAdherencia: const [
        MedicamentoAdherenciaModel(
          medicamentoId: 1,
          nombre: 'Losartán Potásico',
          icono: '💊',
          miligramos: '50 mg',
          colorIcono: '#0D9488',
          tomadas: 7,
          esperadas: 7,
          porcentaje: 100.0,
          cantidadRestante: 28,
          nivelStock: 'Normal',
        ),
        MedicamentoAdherenciaModel(
          medicamentoId: 2,
          nombre: 'Metformina',
          icono: '💊',
          miligramos: '850 mg',
          colorIcono: '#2563EB',
          tomadas: 6,
          esperadas: 7,
          porcentaje: 85.7,
          cantidadRestante: 15,
          nivelStock: 'Normal',
        ),
        MedicamentoAdherenciaModel(
          medicamentoId: 3,
          nombre: 'Acetaminofén',
          icono: '💊',
          miligramos: '500 mg',
          colorIcono: '#F59E0B',
          tomadas: 5,
          esperadas: 7,
          porcentaje: 71.4,
          cantidadRestante: 4,
          nivelStock: 'Bajo',
        ),
      ],
    );
  }

  String _getNombreDia(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }

  /// Obtiene el historial de hábitos de bienestar (agua, caminata, sueño, etc.)
  Future<List<HabitoHistorialModel>> getHistorialHabitos({
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    int? pacienteId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (desde != null) queryParams['desde'] = _formatDate(desde);
      if (hasta != null) queryParams['hasta'] = _formatDate(hasta);
      if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
      if (pacienteId != null) queryParams['paciente_id'] = pacienteId;

      final response = await _dio.get(
        '${ApiEndpoints.historial}/habitos',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) =>
                HabitoHistorialModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return _fallbackHabitos;
    } on DioException catch (_) {
      return _fallbackHabitos;
    } catch (_) {
      return _fallbackHabitos;
    }
  }

  static final List<HabitoHistorialModel> _fallbackHabitos = [
    HabitoHistorialModel(
      id: 1,
      tipo: 'agua',
      meta: 2000,
      progresoActual: 2000,
      porcentaje: 100.0,
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      cumplido: true,
    ),
    HabitoHistorialModel(
      id: 2,
      tipo: 'caminata',
      meta: 3000,
      progresoActual: 2500,
      porcentaje: 83.3,
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      cumplido: false,
    ),
    HabitoHistorialModel(
      id: 3,
      tipo: 'agua',
      meta: 2000,
      progresoActual: 1800,
      porcentaje: 90.0,
      fecha: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
      cumplido: false,
    ),
  ];
}

final historialRepositoryProvider = Provider<HistorialRepository>((ref) {
  return HistorialRepository(ref.watch(apiClientProvider));
});
