class ActividadCognitiva {
  final dynamic id;
  final dynamic usuarioId;
  final String tipoJuego;
  final int puntaje;
  final String nivelDificultad;
  final DateTime? fechaRealizacion;
  final String nombreJugador;
  final bool esUsuarioActual;

  ActividadCognitiva({
    required this.id,
    this.usuarioId,
    required this.tipoJuego,
    required this.puntaje,
    this.nivelDificultad = 'intermedio',
    this.fechaRealizacion,
    this.nombreJugador = 'Tú',
    this.esUsuarioActual = true,
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
      nivelDificultad: json['nivel_dificultad']?.toString() ?? 'intermedio',
      fechaRealizacion: fecha ?? DateTime.now(),
      nombreJugador: json['nombre_jugador']?.toString() ?? 'Tú',
      esUsuarioActual: json['es_usuario_actual'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'tipo_juego': tipoJuego,
    'puntaje': puntaje,
    'nivel_dificultad': nivelDificultad,
    'fecha_realizacion': fechaRealizacion?.toIso8601String(),
    'nombre_jugador': nombreJugador,
    'es_usuario_actual': esUsuarioActual,
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

class PuntosPorJuegoModel {
  final String juegoId;
  final String tipoJuego;
  final int totalPuntos;
  final int partidasJugadas;
  final int recordMaximo;
  final bool esMasJugado;
  final int posicion;
  final String medalla;

  PuntosPorJuegoModel({
    required this.juegoId,
    required this.tipoJuego,
    required this.totalPuntos,
    required this.partidasJugadas,
    required this.recordMaximo,
    required this.esMasJugado,
    required this.posicion,
    required this.medalla,
  });

  factory PuntosPorJuegoModel.fromJson(Map<String, dynamic> json) {
    return PuntosPorJuegoModel(
      juegoId: json['juego_id']?.toString() ?? '',
      tipoJuego: json['tipo_juego']?.toString() ?? '',
      totalPuntos: (json['total_puntos'] as num?)?.toInt() ?? 0,
      partidasJugadas: (json['partidas_jugadas'] as num?)?.toInt() ?? 0,
      recordMaximo: (json['record_maximo'] as num?)?.toInt() ?? 0,
      esMasJugado: json['es_mas_jugado'] as bool? ?? false,
      posicion: (json['posicion'] as num?)?.toInt() ?? 1,
      medalla: json['medalla']?.toString() ?? '🏅',
    );
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

class PodioFamiliarItemModel {
  final int posicion;
  final int usuarioId;
  final String nombre;
  final String rol;
  final String parentesco;
  final int puntajeMaximo;
  final int totalPuntos;
  final int partidasJugadas;
  final String juegoRecord;
  final String medalla;
  final bool esUsuarioActual;

  PodioFamiliarItemModel({
    required this.posicion,
    required this.usuarioId,
    required this.nombre,
    required this.rol,
    required this.parentesco,
    required this.puntajeMaximo,
    required this.totalPuntos,
    required this.partidasJugadas,
    required this.juegoRecord,
    required this.medalla,
    required this.esUsuarioActual,
  });

  factory PodioFamiliarItemModel.fromJson(Map<String, dynamic> json) {
    return PodioFamiliarItemModel(
      posicion: (json['posicion'] as num?)?.toInt() ?? 1,
      usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString() ?? 'Familiar',
      rol: json['rol']?.toString() ?? 'adulto_mayor',
      parentesco: json['parentesco']?.toString() ?? 'Familiar',
      puntajeMaximo: (json['puntaje_maximo'] as num?)?.toInt() ?? 0,
      totalPuntos: (json['total_puntos'] as num?)?.toInt() ?? 0,
      partidasJugadas: (json['partidas_jugadas'] as num?)?.toInt() ?? 0,
      juegoRecord: json['juego_record']?.toString() ?? 'Sin partidas',
      medalla: json['medalla']?.toString() ?? '🏅',
      esUsuarioActual: json['es_usuario_actual'] as bool? ?? false,
    );
  }
}

class PodioFamiliarRespuestaModel {
  final int totalMiembros;
  final bool hayVinculacion;
  final String filtroJuego;
  final String? codigoVinculacionUsuario;
  final List<PodioFamiliarItemModel> podio;

  PodioFamiliarRespuestaModel({
    required this.totalMiembros,
    required this.hayVinculacion,
    required this.filtroJuego,
    this.codigoVinculacionUsuario,
    required this.podio,
  });

  factory PodioFamiliarRespuestaModel.fromJson(Map<String, dynamic> json) {
    final list = (json['podio'] as List? ?? [])
        .map((item) => PodioFamiliarItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return PodioFamiliarRespuestaModel(
      totalMiembros: (json['total_miembros'] as num?)?.toInt() ?? list.length,
      hayVinculacion: json['hay_vinculacion'] as bool? ?? (list.length > 1),
      filtroJuego: json['filtro_juego']?.toString() ?? 'Todos',
      codigoVinculacionUsuario: json['codigo_vinculacion_usuario']?.toString(),
      podio: list,
    );
  }

  factory PodioFamiliarRespuestaModel.vacio() {
    return PodioFamiliarRespuestaModel(
      totalMiembros: 0,
      hayVinculacion: false,
      filtroJuego: 'Todos',
      codigoVinculacionUsuario: null,
      podio: [],
    );
  }
}
