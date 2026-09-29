class ActividadCognitiva {
  final dynamic id;
  final dynamic usuarioId;
  final String tipoJuego;
  final int puntaje;
  final DateTime? fechaRealizacion;

  ActividadCognitiva({
    required this.id,
    this.usuarioId,
    required this.tipoJuego,
    required this.puntaje,
    this.fechaRealizacion,
  });

  factory ActividadCognitiva.fromJson(Map<String, dynamic> json) {
    DateTime? fecha;
    final fStr = json['fecha_realizacion'] ?? json['fecha'] ?? json['created_at'];
    if (fStr != null) {
      try {
        fecha = DateTime.parse(fStr.toString());
      } catch (_) {}
    }
    return ActividadCognitiva(
      id: json['id'],
      usuarioId: json['usuario_id'],
      tipoJuego: json['tipo_juego']?.toString() ?? json['tipo']?.toString() ?? 'Juego Cognitivo',
      puntaje: (json['puntaje'] as num?)?.toInt() ?? 0,
      fechaRealizacion: fecha ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'tipo_juego': tipoJuego,
    'puntaje': puntaje,
    'fecha_realizacion': fechaRealizacion?.toIso8601String(),
  };

  String get fechaFormateada {
    if (fechaRealizacion == null) return 'Reciente';
    final f = fechaRealizacion!;
    final diff = DateTime.now().difference(f);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }
}

class EstadisticasJuegosModel {
  final int totalPuntos;
  final int partidasJugadas;
  final int recordMaximo;
  final String juegoFavorito;

  EstadisticasJuegosModel({
    required this.totalPuntos,
    required this.partidasJugadas,
    required this.recordMaximo,
    required this.juegoFavorito,
  });

  factory EstadisticasJuegosModel.fromJson(Map<String, dynamic> json) {
    return EstadisticasJuegosModel(
      totalPuntos: (json['total_puntos'] as num?)?.toInt() ?? 0,
      partidasJugadas: (json['partidas_jugadas'] as num?)?.toInt() ?? 0,
      recordMaximo: (json['record_maximo'] as num?)?.toInt() ?? 0,
      juegoFavorito: json['juego_favorito']?.toString() ?? 'Ninguno aún',
    );
  }

  factory EstadisticasJuegosModel.vacio() {
    return EstadisticasJuegosModel(
      totalPuntos: 0,
      partidasJugadas: 0,
      recordMaximo: 0,
      juegoFavorito: 'Ninguno aún',
    );
  }
}
