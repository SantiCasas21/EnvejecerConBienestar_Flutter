class HistorialTomaModel {
  final int id;
  final int usuarioId;
  final int medicamentoId;
  final String? medicamentoNombre;
  final String medicamentoIcono;
  final String? medicamentoMiligramos;
  final String medicamentoColor;
  final String fecha;
  final String horaProgramada;
  final String? horaReal;
  final String estado; // 'tomada', 'pospuesta', 'omitida'
  final String? notas;
  final String? createdAt;

  const HistorialTomaModel({
    required this.id,
    required this.usuarioId,
    required this.medicamentoId,
    this.medicamentoNombre,
    this.medicamentoIcono = '💊',
    this.medicamentoMiligramos,
    this.medicamentoColor = '#0D9488',
    required this.fecha,
    required this.horaProgramada,
    this.horaReal,
    this.estado = 'tomada',
    this.notas,
    this.createdAt,
  });

  factory HistorialTomaModel.fromJson(Map<String, dynamic> json) {
    return HistorialTomaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
      medicamentoId: (json['medicamento_id'] as num?)?.toInt() ?? 0,
      medicamentoNombre: json['medicamento_nombre']?.toString(),
      medicamentoIcono: json['medicamento_icono']?.toString() ?? '💊',
      medicamentoMiligramos: json['medicamento_miligramos']?.toString(),
      medicamentoColor: json['medicamento_color']?.toString() ?? '#0D9488',
      fecha: json['fecha']?.toString() ?? '',
      horaProgramada: json['hora_programada']?.toString() ?? '',
      horaReal: json['hora_real']?.toString(),
      estado: json['estado']?.toString() ?? 'tomada',
      notas: json['notas']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'medicamento_id': medicamentoId,
        'medicamento_nombre': medicamentoNombre,
        'medicamento_icono': medicamentoIcono,
        'medicamento_miligramos': medicamentoMiligramos,
        'medicamento_color': medicamentoColor,
        'fecha': fecha,
        'hora_programada': horaProgramada,
        'hora_real': horaReal,
        'estado': estado,
        'notas': notas,
        'created_at': createdAt,
      };

  bool get fueTomada => estado == 'tomada';
  bool get fuePospuesta => estado == 'pospuesta';
  bool get fueOmitida => estado == 'omitida';

  HistorialTomaModel copyWith({
    int? id,
    int? usuarioId,
    int? medicamentoId,
    String? medicamentoNombre,
    String? medicamentoIcono,
    String? medicamentoMiligramos,
    String? medicamentoColor,
    String? fecha,
    String? horaProgramada,
    String? horaReal,
    String? estado,
    String? notas,
    String? createdAt,
  }) {
    return HistorialTomaModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      medicamentoId: medicamentoId ?? this.medicamentoId,
      medicamentoNombre: medicamentoNombre ?? this.medicamentoNombre,
      medicamentoIcono: medicamentoIcono ?? this.medicamentoIcono,
      medicamentoMiligramos: medicamentoMiligramos ?? this.medicamentoMiligramos,
      medicamentoColor: medicamentoColor ?? this.medicamentoColor,
      fecha: fecha ?? this.fecha,
      horaProgramada: horaProgramada ?? this.horaProgramada,
      horaReal: horaReal ?? this.horaReal,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
