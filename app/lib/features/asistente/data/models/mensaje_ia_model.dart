class AccionPendienteModel {
  final String tipo;
  final String resumen;
  final Map<String, dynamic> datos;
  final String estado; // 'pendiente' | 'confirmada' | 'cancelada'

  const AccionPendienteModel({
    required this.tipo,
    required this.resumen,
    required this.datos,
    this.estado = 'pendiente',
  });

  factory AccionPendienteModel.fromJson(Map<String, dynamic> json) {
    return AccionPendienteModel(
      tipo: json['tipo']?.toString() ?? '',
      resumen: json['resumen']?.toString() ?? '',
      datos: (json['datos'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['datos'] as Map)
          : <String, dynamic>{},
      estado: json['estado']?.toString() ?? 'pendiente',
    );
  }

  bool get estaPendiente => estado == 'pendiente';
  bool get estaConfirmada => estado == 'confirmada';
  bool get estaCancelada => estado == 'cancelada';
}

class MensajeIaModel {
  final int id;
  final String rol; // 'user' | 'assistant'
  final String contenido;
  final String? alertaPreventiva;
  final bool esEmergencia;
  final AccionPendienteModel? accionPendiente;
  final List<String> entidadesActualizadas;
  final String? createdAt;

  const MensajeIaModel({
    required this.id,
    required this.rol,
    required this.contenido,
    this.alertaPreventiva,
    this.esEmergencia = false,
    this.accionPendiente,
    this.entidadesActualizadas = const [],
    this.createdAt,
  });

  bool get esUsuario => rol == 'user';
  bool get esAsistente => rol == 'assistant';

  factory MensajeIaModel.fromJson(Map<String, dynamic> json) {
    final rawAccion = json['accion_pendiente'];
    final rawEntidades = json['entidades_actualizadas'];

    return MensajeIaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rol: json['rol']?.toString() ?? 'assistant',
      contenido: json['contenido']?.toString() ?? '',
      alertaPreventiva: json['alerta_preventiva']?.toString(),
      esEmergencia: json['es_emergencia'] == true,
      accionPendiente: (rawAccion is Map<String, dynamic>)
          ? AccionPendienteModel.fromJson(rawAccion)
          : null,
      entidadesActualizadas: (rawEntidades is List)
          ? rawEntidades.map((e) => e.toString()).toList()
          : const [],
      createdAt: json['created_at']?.toString(),
    );
  }
}
