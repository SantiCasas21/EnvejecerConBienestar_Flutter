import 'racha_model.dart';

class CumplimientoDiarioModel {
  final String fecha;
  final String diaSemana;
  final int esperadas;
  final int tomadas;
  final int pospuestas;
  final int omitidas;
  final double porcentaje;

  const CumplimientoDiarioModel({
    required this.fecha,
    required this.diaSemana,
    required this.esperadas,
    required this.tomadas,
    required this.pospuestas,
    required this.omitidas,
    required this.porcentaje,
  });

  factory CumplimientoDiarioModel.fromJson(Map<String, dynamic> json) {
    return CumplimientoDiarioModel(
      fecha: json['fecha']?.toString() ?? '',
      diaSemana: json['dia_semana']?.toString() ?? '',
      esperadas: (json['esperadas'] as num?)?.toInt() ?? 0,
      tomadas: (json['tomadas'] as num?)?.toInt() ?? 0,
      pospuestas: (json['pospuestas'] as num?)?.toInt() ?? 0,
      omitidas: (json['omitidas'] as num?)?.toInt() ?? 0,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fecha': fecha,
        'dia_semana': diaSemana,
        'esperadas': esperadas,
        'tomadas': tomadas,
        'pospuestas': pospuestas,
        'omitidas': omitidas,
        'porcentaje': porcentaje,
      };
}

class MedicamentoAdherenciaModel {
  final int medicamentoId;
  final String nombre;
  final String icono;
  final String? miligramos;
  final String colorIcono;
  final int tomadas;
  final int esperadas;
  final double porcentaje;
  final int? cantidadRestante;
  final String? nivelStock;

  const MedicamentoAdherenciaModel({
    required this.medicamentoId,
    required this.nombre,
    this.icono = '💊',
    this.miligramos,
    this.colorIcono = '#0D9488',
    required this.tomadas,
    required this.esperadas,
    required this.porcentaje,
    this.cantidadRestante,
    this.nivelStock,
  });

  factory MedicamentoAdherenciaModel.fromJson(Map<String, dynamic> json) {
    return MedicamentoAdherenciaModel(
      medicamentoId: (json['medicamento_id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      icono: json['icono']?.toString() ?? '💊',
      miligramos: json['miligramos']?.toString(),
      colorIcono: json['color_icono']?.toString() ?? '#0D9488',
      tomadas: (json['tomadas'] as num?)?.toInt() ?? 0,
      esperadas: (json['esperadas'] as num?)?.toInt() ?? 0,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0.0,
      cantidadRestante: (json['cantidad_restante'] as num?)?.toInt(),
      nivelStock: json['nivel_stock']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'medicamento_id': medicamentoId,
        'nombre': nombre,
        'icono': icono,
        'miligramos': miligramos,
        'color_icono': colorIcono,
        'tomadas': tomadas,
        'esperadas': esperadas,
        'porcentaje': porcentaje,
        'cantidad_restante': cantidadRestante,
        'nivel_stock': nivelStock,
      };
}

class HabitoResumenModel {
  final String nombre;
  final String icono;
  final int cumplidos;
  final int totalDias;
  final double porcentaje;

  const HabitoResumenModel({
    required this.nombre,
    this.icono = '🌿',
    required this.cumplidos,
    required this.totalDias,
    required this.porcentaje,
  });

  factory HabitoResumenModel.fromJson(Map<String, dynamic> json) {
    return HabitoResumenModel(
      nombre: json['nombre']?.toString() ?? '',
      icono: json['icono']?.toString() ?? '🌿',
      cumplidos: (json['cumplidos'] as num?)?.toInt() ?? 0,
      totalDias: (json['total_dias'] as num?)?.toInt() ?? 1,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'icono': icono,
        'cumplidos': cumplidos,
        'total_dias': totalDias,
        'porcentaje': porcentaje,
      };
}

class ResumenAdherenciaModel {
  final int usuarioId;
  final String fechaInicio;
  final String fechaFin;
  final int totalEsperadas;
  final int totalTomadas;
  final int totalPospuestas;
  final int totalOmitidas;
  final double porcentajeAdherenciaGlobal;
  final List<CumplimientoDiarioModel> cumplimientoDiario;
  final List<MedicamentoAdherenciaModel> medicamentosAdherencia;
  final List<HabitoResumenModel> resumenHabitos;
  final RachaModel? racha;

  const ResumenAdherenciaModel({
    required this.usuarioId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.totalEsperadas,
    required this.totalTomadas,
    required this.totalPospuestas,
    required this.totalOmitidas,
    required this.porcentajeAdherenciaGlobal,
    this.cumplimientoDiario = const [],
    this.medicamentosAdherencia = const [],
    this.resumenHabitos = const [],
    this.racha,
  });

  factory ResumenAdherenciaModel.fromJson(Map<String, dynamic> json) {
    return ResumenAdherenciaModel(
      usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      totalEsperadas: (json['total_esperadas'] as num?)?.toInt() ?? 0,
      totalTomadas: (json['total_tomadas'] as num?)?.toInt() ?? 0,
      totalPospuestas: (json['total_pospuestas'] as num?)?.toInt() ?? 0,
      totalOmitidas: (json['total_omitidas'] as num?)?.toInt() ?? 0,
      porcentajeAdherenciaGlobal:
          (json['porcentaje_adherencia_global'] as num?)?.toDouble() ?? 0.0,
      cumplimientoDiario: (json['cumplimiento_diario'] as List<dynamic>?)
              ?.map((e) =>
                  CumplimientoDiarioModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      medicamentosAdherencia: (json['medicamentos_adherencia'] as List<dynamic>?)
              ?.map((e) => MedicamentoAdherenciaModel.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      resumenHabitos: (json['resumen_habitos'] as List<dynamic>?)
              ?.map((e) => HabitoResumenModel.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      racha: json['racha'] != null
          ? RachaModel.fromJson(Map<String, dynamic>.from(json['racha'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
        'total_esperadas': totalEsperadas,
        'total_tomadas': totalTomadas,
        'total_pospuestas': totalPospuestas,
        'total_omitidas': totalOmitidas,
        'porcentaje_adherencia_global': porcentajeAdherenciaGlobal,
        'cumplimiento_diario': cumplimientoDiario.map((e) => e.toJson()).toList(),
        'medicamentos_adherencia':
            medicamentosAdherencia.map((e) => e.toJson()).toList(),
        'resumen_habitos': resumenHabitos.map((e) => e.toJson()).toList(),
        'racha': racha?.toJson(),
      };
}

class HabitoHistorialModel {
  final int id;
  final String tipo;
  final int meta;
  final int progresoActual;
  final double porcentaje;
  final String fecha;
  final bool cumplido;

  const HabitoHistorialModel({
    required this.id,
    required this.tipo,
    required this.meta,
    required this.progresoActual,
    required this.porcentaje,
    required this.fecha,
    required this.cumplido,
  });

  factory HabitoHistorialModel.fromJson(Map<String, dynamic> json) {
    return HabitoHistorialModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipo: json['tipo']?.toString() ?? '',
      meta: (json['meta'] as num?)?.toInt() ?? 0,
      progresoActual: (json['progreso_actual'] as num?)?.toInt() ?? 0,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fecha']?.toString() ?? '',
      cumplido: json['cumplido'] == true,
    );
  }

  String get nombreFormateado {
    final tipoLower = tipo.toLowerCase();
    if (tipoLower.contains('agua') || tipoLower.contains('hidratacion')) {
      return 'Hidratación';
    } else if (tipoLower.contains('camin') || tipoLower.contains('paso') || tipoLower.contains('ejercicio')) {
      return 'Caminata y Movimiento';
    } else if (tipoLower.contains('juego') || tipoLower.contains('mental') || tipoLower.contains('cogniti')) {
      return 'Gimnasio Mental';
    }
    return tipo.isEmpty ? 'Hábito Saludable' : tipo;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'meta': meta,
        'progreso_actual': progresoActual,
        'porcentaje': porcentaje,
        'fecha': fecha,
        'cumplido': cumplido,
      };
}
