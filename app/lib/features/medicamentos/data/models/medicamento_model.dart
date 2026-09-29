import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medicamento_model.freezed.dart';
part 'medicamento_model.g.dart';

@freezed
class Medicamento with _$Medicamento {
  const Medicamento._();

  const factory Medicamento({
    required dynamic id,
    required String nombre,
    String? miligramos,
    String? notas,
    int? frecuencia, // en horas
    @JsonKey(name: 'hora_alarma') String? horaAlarma, // HH:mm:ss o HH:mm
    @JsonKey(name: 'esta_tomado', defaultValue: false) bool? estaTomado,
    @JsonKey(name: 'cantidad_restante', defaultValue: 30) int? cantidadRestante,
    @JsonKey(name: 'umbral_alerta', defaultValue: 5) int? umbralAlerta,
    @Default('💊') String icono,
    @JsonKey(name: 'color_icono', defaultValue: '#0D9488') @Default('#0D9488') String? colorIcono,
    @JsonKey(name: 'fecha_inicio') String? fechaInicio,
    @JsonKey(name: 'tratamiento_id') int? tratamientoId,
  }) = _Medicamento;

  factory Medicamento.fromJson(Map<String, dynamic> json) =>
      _$MedicamentoFromJson(json);

  String get textoBoton => (estaTomado ?? false) ? '✓ Tomado' : 'Marcar tomado';

  bool get alertaInventario =>
      (cantidadRestante != null && umbralAlerta != null && cantidadRestante! > 0)
          ? cantidadRestante! <= umbralAlerta!
          : false;

  String get textoInventario {
    if (cantidadRestante == null || cantidadRestante! <= 0) {
      return 'Sin pastillas disponibles';
    }
    return 'Quedan $cantidadRestante pastillas';
  }

  /// Calcula cuántas tomas corresponden al día según la frecuencia
  int get tomasPorDia => horarioDiario.isNotEmpty ? horarioDiario.length : 1;

  /// Calcula los días estimados de medicación restantes según la cantidad actual
  int get diasAutonomia {
    if (cantidadRestante == null || cantidadRestante! <= 0) return 0;
    final tomas = tomasPorDia > 0 ? tomasPorDia : 1;
    return (cantidadRestante! / tomas).floor();
  }

  /// Nivel de stock para semáforo: 'agotado', 'critico', 'bajo', 'optimo'
  String get nivelStock {
    if (cantidadRestante == null || cantidadRestante! <= 0) return 'agotado';
    if (diasAutonomia <= 2) return 'critico';
    if (alertaInventario || diasAutonomia <= 7) return 'bajo';
    return 'optimo';
  }

  /// Color semáforo de inventario
  Color get colorStock {
    switch (nivelStock) {
      case 'agotado':
      case 'critico':
        return const Color(0xFFE11D48); // Rojo
      case 'bajo':
        return const Color(0xFFF59E0B); // Ámbar / Amarillo
      case 'optimo':
      default:
        return const Color(0xFF22C55E); // Verde
    }
  }

  /// Calcula la lista de horas de tomas en el transcurso del día
  List<TimeOfDay> get horarioDiario {
    final List<TimeOfDay> horarios = [];
    final int freq = (frecuencia != null && frecuencia! > 0) ? frecuencia! : 24;

    int horaInicial = 8;
    int minutoInicial = 0;

    if (horaAlarma != null && horaAlarma!.isNotEmpty) {
      final partes = horaAlarma!.split(':');
      if (partes.isNotEmpty) {
        final parsedH = int.tryParse(partes[0]) ?? 8;
        horaInicial = (parsedH >= 0 && parsedH < 24) ? parsedH : 8;
      }
      if (partes.length > 1) {
        final parsedM = int.tryParse(partes[1]) ?? 0;
        minutoInicial = (parsedM >= 0 && parsedM < 60) ? parsedM : 0;
      }
    }

    final int step = freq > 0 ? freq : 24;
    int currentHour = horaInicial;
    while (currentHour < 24 && currentHour >= 0) {
      horarios.add(TimeOfDay(hour: currentHour, minute: minutoInicial));
      currentHour += step;
    }

    if (horarios.isEmpty) {
      horarios.add(TimeOfDay(hour: horaInicial, minute: minutoInicial));
    }

    return horarios;
  }

  /// Formatea un TimeOfDay a formato 12 horas accesible (ej: 08:00 AM, 02:30 PM)
  static String formatearTimeOfDay(TimeOfDay time) {
    final int hour12 = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final String period = time.hour >= 12 ? 'PM' : 'AM';
    final String hourStr = hour12.toString().padLeft(2, '0');
    final String minStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr $period';
  }

  /// Hora de la primera alarma en formato 12 horas legible para adultos mayores
  String get horaAlarma12 {
    if (horarioDiario.isNotEmpty) {
      return formatearTimeOfDay(horarioDiario.first);
    }
    return '08:00 AM';
  }

  /// Resumen en una sola línea de todas las alarmas del día (ej: 08:00 AM · 04:00 PM)
  String get resumenHoras12 {
    final list = horarioDiario;
    if (list.isEmpty) return 'Sin alarmas programadas';
    return list.map((t) => formatearTimeOfDay(t)).join(' · ');
  }

  /// Texto amigable de desglose de tomas
  String get textoHorario {
    final lista = horarioDiario;
    if (lista.isEmpty) return 'Sin horario programado';

    return lista.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final h = entry.value;
      return '  • Toma $idx: ${formatearTimeOfDay(h)}';
    }).join('\n');
  }

  /// Hora formateada de la primera alarma (24h)
  String get horaAlarmaFormateada {
    if (horaAlarma != null && horaAlarma!.isNotEmpty) {
      final partes = horaAlarma!.split(':');
      if (partes.length >= 2) {
        return '${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}';
      }
    }
    return '08:00';
  }
}
