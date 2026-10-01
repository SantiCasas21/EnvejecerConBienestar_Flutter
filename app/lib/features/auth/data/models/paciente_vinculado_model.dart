class PacienteVinculadoModel {
  final int id;
  final String nombre;
  final String email;
  final String? codigoVinculacion;
  final String parentesco;
  final String? fechaVinculacion;
  final int? edad;
  final String? genero;
  final String? tipoSangre;
  final String? eps;
  final String? alergias;
  final String? condiciones;
  final String? telefono;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  final int totalMedicamentos;
  final int tomasCumplidas;
  final int tomasPendientes;
  final int alertasStock;
  final List<String> medicamentosAlerta;
  final Map<String, dynamic>? proximaToma;
  final List<Map<String, dynamic>> medicamentos;

  const PacienteVinculadoModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.codigoVinculacion,
    this.parentesco = 'Familiar / Cuidador',
    this.fechaVinculacion,
    this.edad,
    this.genero,
    this.tipoSangre,
    this.eps,
    this.alergias,
    this.condiciones,
    this.telefono,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    this.totalMedicamentos = 0,
    this.tomasCumplidas = 0,
    this.tomasPendientes = 0,
    this.alertasStock = 0,
    this.medicamentosAlerta = const [],
    this.proximaToma,
    this.medicamentos = const [],
  });

  factory PacienteVinculadoModel.fromJson(Map<String, dynamic> json) {
    return PacienteVinculadoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString() ?? 'Adulto Mayor',
      email: json['email']?.toString() ?? '',
      codigoVinculacion: json['codigo_vinculacion']?.toString(),
      parentesco: json['parentesco']?.toString() ?? 'Familiar / Cuidador',
      fechaVinculacion: json['fecha_vinculacion']?.toString(),
      edad: (json['edad'] as num?)?.toInt(),
      genero: json['genero']?.toString(),
      tipoSangre: json['tipo_sangre']?.toString(),
      eps: json['eps']?.toString(),
      alergias: json['alergias']?.toString(),
      condiciones: json['condiciones']?.toString(),
      telefono: json['telefono']?.toString(),
      contactoEmergenciaNombre: json['contacto_emergencia_nombre']?.toString(),
      contactoEmergenciaTelefono: json['contacto_emergencia_telefono']?.toString(),
      totalMedicamentos: (json['total_medicamentos'] as num?)?.toInt() ?? 0,
      tomasCumplidas: (json['tomas_cumplidas'] as num?)?.toInt() ?? 0,
      tomasPendientes: (json['tomas_pendientes'] as num?)?.toInt() ?? 0,
      alertasStock: (json['alertas_stock'] as num?)?.toInt() ?? 0,
      medicamentosAlerta: (json['medicamentos_alerta'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      proximaToma: json['proxima_toma'] as Map<String, dynamic>?,
      medicamentos: (json['medicamentos'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'codigo_vinculacion': codigoVinculacion,
        'parentesco': parentesco,
        'fecha_vinculacion': fechaVinculacion,
        'edad': edad,
        'genero': genero,
        'tipo_sangre': tipoSangre,
        'eps': eps,
        'alergias': alergias,
        'condiciones': condiciones,
        'telefono': telefono,
        'contacto_emergencia_nombre': contactoEmergenciaNombre,
        'contacto_emergencia_telefono': contactoEmergenciaTelefono,
        'total_medicamentos': totalMedicamentos,
        'tomas_cumplidas': tomasCumplidas,
        'tomas_pendientes': tomasPendientes,
        'alertas_stock': alertasStock,
        'medicamentos_alerta': medicamentosAlerta,
        'proxima_toma': proximaToma,
        'medicamentos': medicamentos,
      };

  double get porcentajeTomas =>
      totalMedicamentos == 0 ? 1.0 : (tomasCumplidas / totalMedicamentos).clamp(0.0, 1.0);

  int get porcentajeTomasEntero => (porcentajeTomas * 100).round();

  bool get todasTomasCompletadas =>
      totalMedicamentos > 0 && tomasCumplidas >= totalMedicamentos;

  bool get tieneAlertasStock => alertasStock > 0 || medicamentosBajoStock.isNotEmpty;

  List<Map<String, dynamic>> get medicamentosEnCola => medicamentos;

  List<Map<String, dynamic>> get medicamentosBajoStock => medicamentos
      .where((m) =>
          m['alerta_inventario'] == true ||
          ((m['cantidad_restante'] as num?)?.toInt() ?? 999) <=
              ((m['umbral_alerta'] as num?)?.toInt() ?? 5))
      .toList();

  String? get telefonoContactoDirecto {
    if (telefono != null && telefono!.trim().isNotEmpty) {
      return telefono!.trim();
    }
    if (contactoEmergenciaTelefono != null &&
        contactoEmergenciaTelefono!.trim().isNotEmpty) {
      return contactoEmergenciaTelefono!.trim();
    }
    return null;
  }

  PacienteVinculadoModel copyWith({
    int? id,
    String? nombre,
    String? email,
    String? codigoVinculacion,
    String? parentesco,
    String? fechaVinculacion,
    int? edad,
    String? genero,
    String? tipoSangre,
    String? eps,
    String? alergias,
    String? condiciones,
    String? telefono,
    String? contactoEmergenciaNombre,
    String? contactoEmergenciaTelefono,
    int? totalMedicamentos,
    int? tomasCumplidas,
    int? tomasPendientes,
    int? alertasStock,
    List<String>? medicamentosAlerta,
    Map<String, dynamic>? proximaToma,
    List<Map<String, dynamic>>? medicamentos,
  }) {
    return PacienteVinculadoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      codigoVinculacion: codigoVinculacion ?? this.codigoVinculacion,
      parentesco: parentesco ?? this.parentesco,
      fechaVinculacion: fechaVinculacion ?? this.fechaVinculacion,
      edad: edad ?? this.edad,
      genero: genero ?? this.genero,
      tipoSangre: tipoSangre ?? this.tipoSangre,
      eps: eps ?? this.eps,
      alergias: alergias ?? this.alergias,
      condiciones: condiciones ?? this.condiciones,
      telefono: telefono ?? this.telefono,
      contactoEmergenciaNombre:
          contactoEmergenciaNombre ?? this.contactoEmergenciaNombre,
      contactoEmergenciaTelefono:
          contactoEmergenciaTelefono ?? this.contactoEmergenciaTelefono,
      totalMedicamentos: totalMedicamentos ?? this.totalMedicamentos,
      tomasCumplidas: tomasCumplidas ?? this.tomasCumplidas,
      tomasPendientes: tomasPendientes ?? this.tomasPendientes,
      alertasStock: alertasStock ?? this.alertasStock,
      medicamentosAlerta: medicamentosAlerta ?? this.medicamentosAlerta,
      proximaToma: proximaToma ?? this.proximaToma,
      medicamentos: medicamentos ?? this.medicamentos,
    );
  }
}
