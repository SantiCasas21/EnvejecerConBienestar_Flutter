class DiaSemanaRacha {
  final String letra; // 'L', 'M', 'M', 'J', 'V', 'S', 'D'
  final String fecha;
  final bool activo;
  final bool esHoy;

  const DiaSemanaRacha({
    required this.letra,
    required this.fecha,
    required this.activo,
    required this.esHoy,
  });

  factory DiaSemanaRacha.fromJson(Map<String, dynamic> json) {
    return DiaSemanaRacha(
      letra: json['letra']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      activo: json['activo'] == true,
      esHoy: json['es_hoy'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'letra': letra,
        'fecha': fecha,
        'activo': activo,
        'es_hoy': esHoy,
      };
}

class RachaModel {
  final int usuarioId;
  final int rachaActual;
  final int rachaMejor;
  final String mensajeRacha;
  final List<DiaSemanaRacha> diasSemana;
  final bool hoyCompletado;

  const RachaModel({
    required this.usuarioId,
    required this.rachaActual,
    required this.rachaMejor,
    required this.mensajeRacha,
    this.diasSemana = const [],
    this.hoyCompletado = false,
  });

  factory RachaModel.fromJson(Map<String, dynamic> json) {
    return RachaModel(
      usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
      rachaActual: (json['racha_actual'] as num?)?.toInt() ?? 0,
      rachaMejor: (json['racha_mejor'] as num?)?.toInt() ?? 0,
      mensajeRacha: json['mensaje_racha']?.toString() ?? '¡Enciende tu llama de salud! 🔥',
      diasSemana: (json['dias_semana'] as List<dynamic>?)
              ?.map((d) => DiaSemanaRacha.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      hoyCompletado: json['hoy_completado'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
        'racha_actual': rachaActual,
        'racha_mejor': rachaMejor,
        'mensaje_racha': mensajeRacha,
        'dias_semana': diasSemana.map((d) => d.toJson()).toList(),
        'hoy_completado': hoyCompletado,
      };
}
