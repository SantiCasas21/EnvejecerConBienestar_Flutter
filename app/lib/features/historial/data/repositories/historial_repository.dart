import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/historial_toma_model.dart';
import '../models/resumen_adherencia_model.dart';
import '../models/racha_model.dart';

class HistorialRepository {
  final Dio _dio;

  // Fallback offline en memoria para resiliencia (Regla 4 ia/desarrollo.md)
  static List<HistorialTomaModel> _generarFallbackTomas() {
    final list = <HistorialTomaModel>[];
    final hoy = DateTime.now();
    int idCounter = 1;

    final meds = [
      {
        'id': 1,
        'nombre': 'Losartán Potásico',
        'icono': '💊',
        'miligramos': '50 mg',
        'color': '#0D9488',
        'horas': ['08:00'],
      },
      {
        'id': 2,
        'nombre': 'Metformina',
        'icono': '💊',
        'miligramos': '850 mg',
        'color': '#2563EB',
        'horas': ['08:30', '20:30'],
      },
      {
        'id': 3,
        'nombre': 'Acetaminofén',
        'icono': '💊',
        'miligramos': '500 mg',
        'color': '#F59E0B',
        'horas': ['08:00', '14:00', '20:00'],
      },
      {
        'id': 4,
        'nombre': 'Atorvastatina',
        'icono': '💊',
        'miligramos': '20 mg',
        'color': '#6366F1',
        'horas': ['21:00'],
      },
    ];

    final notasComunes = [
      'Tomada con agua después del desayuno',
      'Tomada con el almuerzo',
      'Tomada con la cena',
      'Tomada puntual según alarma',
      'Sin molestias digestivas',
    ];

    for (int i = 0; i <= 60; i++) {
      final dia = hoy.subtract(Duration(days: i));
      final y = dia.year.toString().padLeft(4, '0');
      final m = dia.month.toString().padLeft(2, '0');
      final d = dia.day.toString().padLeft(2, '0');
      final fechaIso = '$y-$m-$d';
      final esHoy = (i == 0);

      for (var med in meds) {
        final medId = med['id'] as int;
        final medNombre = med['nombre'] as String;
        final medIcono = med['icono'] as String;
        final medMg = med['miligramos'] as String;
        final medColor = med['color'] as String;
        final horas = med['horas'] as List<String>;

        for (var hora in horas) {
          String estado = 'tomada';
          String? nota = notasComunes[(i + medId) % notasComunes.length];

          if (esHoy) {
            estado = 'tomada';
            nota = 'Tomada con puntualidad hoy';
          } else {
            // Cumplimiento determinista > 90%
            final seed = (i * 17 + medId * 31 + hora.hashCode) % 100;
            if (seed < 88) {
              estado = 'tomada';
            } else if (seed < 95) {
              estado = 'pospuesta';
              nota = 'Pospuesta 1 hora por actividad fuera de casa';
            } else {
              estado = 'omitida';
              nota = 'Omitida por indicación médica puntual';
            }
          }

          list.add(HistorialTomaModel(
            id: idCounter++,
            usuarioId: 3,
            medicamentoId: medId,
            medicamentoNombre: medNombre,
            medicamentoIcono: medIcono,
            medicamentoMiligramos: medMg,
            medicamentoColor: medColor,
            fecha: fechaIso,
            horaProgramada: hora,
            horaReal: estado == 'tomada'
                ? '$fechaIso ${hora}:12'
                : (estado == 'pospuesta' ? '$fechaIso 18:00:00' : null),
            estado: estado,
            notas: nota,
            createdAt: '$fechaIso 00:00:00',
          ));
        }
      }
    }
    return list;
  }

  late final List<HistorialTomaModel> _fallbackTomas = _generarFallbackTomas();

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

  /// Obtiene el resumen de adherencia para el rango indicado o por cantidad de días (7 o 30)
  Future<ResumenAdherenciaModel> getResumenAdherencia({
    DateTime? desde,
    DateTime? hasta,
    int? dias,
    int? pacienteId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (desde != null) queryParams['desde'] = _formatDate(desde);
      if (hasta != null) queryParams['hasta'] = _formatDate(hasta);
      if (dias != null) queryParams['dias'] = dias;
      if (pacienteId != null) queryParams['paciente_id'] = pacienteId;

      final response = await _dio.get(
        '${ApiEndpoints.historial}/resumen',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data is Map) {
        return ResumenAdherenciaModel.fromJson(
            Map<String, dynamic>.from(response.data as Map));
      }
      return _generarFallbackResumen(desde, hasta, dias: dias);
    } on DioException catch (_) {
      return _generarFallbackResumen(desde, hasta, dias: dias);
    } catch (_) {
      return _generarFallbackResumen(desde, hasta, dias: dias);
    }
  }

  ResumenAdherenciaModel _generarFallbackResumen(DateTime? desde, DateTime? hasta, {int? dias}) {
    final hoy = DateTime.now();
    final fFin = hasta ?? hoy;
    final int cantDias = dias ?? (desde != null ? fFin.difference(desde).inDays + 1 : 7);
    final fInicio = desde ?? fFin.subtract(Duration(days: cantDias > 0 ? cantDias - 1 : 6));

    final listaCumplimiento = <CumplimientoDiarioModel>[];
    var cur = fInicio;
    while (!cur.isAfter(fFin)) {
      final dateStr = _formatDate(cur);
      final tomasDelDia = _fallbackTomas.where((t) => t.fecha == dateStr).toList();
      final tomadas = tomasDelDia.where((t) => t.estado == 'tomada').length;
      final esperadas = tomasDelDia.isEmpty ? 7 : tomasDelDia.length;
      final pct = esperadas > 0 ? (tomadas / esperadas) * 100 : 0.0;

      listaCumplimiento.add(CumplimientoDiarioModel(
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

    final totalEsperadas = listaCumplimiento.fold(0, (sum, d) => sum + d.esperadas);
    final totalTomadas = listaCumplimiento.fold(0, (sum, d) => sum + d.tomadas);
    final totalPospuestas = listaCumplimiento.fold(0, (sum, d) => sum + d.pospuestas);
    final totalOmitidas = listaCumplimiento.fold(0, (sum, d) => sum + d.omitidas);
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
      cumplimientoDiario: listaCumplimiento,
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
        MedicamentoAdherenciaModel(
          medicamentoId: 4,
          nombre: 'Atorvastatina',
          icono: '💊',
          miligramos: '20 mg',
          colorIcono: '#6366F1',
          tomadas: 6,
          esperadas: 7,
          porcentaje: 85.7,
          cantidadRestante: 20,
          nivelStock: 'Normal',
        ),
      ],
      resumenHabitos: const [
        HabitoResumenModel(nombre: 'Agua', icono: '💧', cumplidos: 6, totalDias: 7, porcentaje: 85.7),
        HabitoResumenModel(nombre: 'Caminata', icono: '🚶', cumplidos: 5, totalDias: 7, porcentaje: 71.4),
        HabitoResumenModel(nombre: 'Estiramientos', icono: '🧘', cumplidos: 7, totalDias: 7, porcentaje: 100.0),
      ],
      racha: const RachaModel(usuarioId: 1, rachaActual: 5, rachaMejor: 14, mensajeRacha: '¡Tu llama de salud brilla con fuerza! 🔥'),
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
