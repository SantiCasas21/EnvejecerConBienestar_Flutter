import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'perfil_model.freezed.dart';
part 'perfil_model.g.dart';

@freezed
class PerfilModel with _$PerfilModel {
  const PerfilModel._();

  const factory PerfilModel({
    int? id,
    @JsonKey(name: 'usuario_id') int? usuarioId,
    
    // ── Datos Personales y Biométricos ──
    @JsonKey(name: 'fecha_nacimiento') String? fechaNacimiento,
    int? edad,
    @Default('No especificado') String genero,
    @JsonKey(name: 'tipo_sangre', defaultValue: 'O+') @Default('O+') String? tipoSangre,
    double? peso, // en kg
    double? altura, // en cm
    
    // ── Cobertura y Cuidados Clínicos ──
    @Default('No especificada') String eps,
    String? telefono,
    @Default('Ninguna') String alergias,
    @Default('Ninguna') String condiciones,
    @Default('Ninguna') String cirugias,
    @JsonKey(name: 'dispositivos_medicos') @Default('Ninguno') String dispositivosMedicos,
    
    // ── Contactos de Emergencia y Red Médica ──
    @JsonKey(name: 'contacto_emergencia_nombre') String? contactoEmergenciaNombre,
    @JsonKey(name: 'contacto_emergencia_telefono') String? contactoEmergenciaTelefono,
    @JsonKey(name: 'contacto_emergencia_parentesco') @Default('Familiar') String contactoEmergenciaParentesco,
    @JsonKey(name: 'medico_tratante') String? medicoTratante,
    @JsonKey(name: 'telefono_medico') String? telefonoMedico,
    @JsonKey(name: 'clinica_preferida') @Default('Hospital General') String clinicaPreferida,
    
    // ── Cumplimiento Legal: Ley 1581 de 2012 (Habeas Data) ──
    @JsonKey(name: 'acepto_habeas_data', defaultValue: false) @Default(false) bool? aceptoHabeasData,
    @JsonKey(name: 'fecha_habeas_data') String? fechaHabeasData,

    // ── Notas y Observaciones ──
    @JsonKey(name: 'notas_adicionales') String? notasAdicionales,
  }) = _PerfilModel;

  factory PerfilModel.fromJson(Map<String, dynamic> json) =>
      _$PerfilModelFromJson(json);

  /// Cálculo automático de Índice de Masa Corporal (IMC)
  double? get imc {
    if (peso != null && altura != null && altura! > 30 && peso! > 10) {
      final alturaMetros = altura! / 100.0;
      return peso! / (alturaMetros * alturaMetros);
    }
    return null;
  }

  /// Clasificación médica del IMC para adultos mayores
  String get clasificacionImc {
    final valor = imc;
    if (valor == null) return 'No calculado';
    if (valor < 18.5) return 'Bajo peso';
    if (valor < 25.0) return 'Peso saludable';
    if (valor < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// Color para badge de IMC
  Color get colorImc {
    final valor = imc;
    if (valor == null) return const Color(0xFF64748B);
    if (valor >= 18.5 && valor < 25.0) return const Color(0xFF22C55E); // Saludable
    if (valor < 18.5 || (valor >= 25.0 && valor < 30.0)) return const Color(0xFFF97316); // Atención
    return const Color(0xFFE11D48); // Alerta
  }

  /// Formato legible de edad
  String get textoEdad => (edad != null && edad! > 0) ? '$edad años' : 'No especificada';

  /// Porcentaje de completitud de la ficha médica (0.0 a 1.0)
  double get porcentajeCompletitud {
    int totalPuntos = 0;
    int puntosObtenidos = 0;

    // 1. Fecha de Nacimiento o Edad (15 pts)
    totalPuntos += 15;
    if ((fechaNacimiento != null && fechaNacimiento!.isNotEmpty) || (edad != null && edad! > 0)) {
      puntosObtenidos += 15;
    }

    // 2. Género (10 pts)
    totalPuntos += 10;
    if (genero.isNotEmpty && genero != 'No especificado') {
      puntosObtenidos += 10;
    }

    // 3. Tipo de Sangre (15 pts)
    totalPuntos += 15;
    if (tipoSangre != null && tipoSangre!.isNotEmpty) {
      puntosObtenidos += 15;
    }

    // 4. EPS / Aseguradora (15 pts)
    totalPuntos += 15;
    if (eps.isNotEmpty && eps != 'No especificada') {
      puntosObtenidos += 15;
    }

    // 5. Contacto de Emergencia SOS - Teléfono (20 pts - crítico)
    totalPuntos += 20;
    if (contactoEmergenciaTelefono != null && contactoEmergenciaTelefono!.trim().isNotEmpty) {
      puntosObtenidos += 20;
    }

    // 6. Contacto de Emergencia - Nombre (10 pts)
    totalPuntos += 10;
    if (contactoEmergenciaNombre != null && contactoEmergenciaNombre!.trim().isNotEmpty) {
      puntosObtenidos += 10;
    }

    // 7. Alergias o Condiciones (15 pts)
    totalPuntos += 15;
    if (alergias.isNotEmpty || condiciones.isNotEmpty) {
      puntosObtenidos += 15;
    }

    return puntosObtenidos / totalPuntos;
  }

  /// Porcentaje entero (0 a 100)
  int get porcentajeCompletitudEntero => (porcentajeCompletitud * 100).toInt();

  /// Ficha completada al 100%
  bool get estaCompleto => porcentajeCompletitud >= 1.0;

  /// Lista de campos sugeridos que faltan por completar
  List<String> get camposFaltantes {
    final List<String> faltantes = [];

    if ((fechaNacimiento == null || fechaNacimiento!.isEmpty) && (edad == null || edad! == 0)) {
      faltantes.add('Fecha de nacimiento');
    }
    if (contactoEmergenciaTelefono == null || contactoEmergenciaTelefono!.trim().isEmpty) {
      faltantes.add('Contacto de emergencia SOS');
    }
    if (eps.isEmpty || eps == 'No especificada') {
      faltantes.add('EPS / Seguro');
    }
    if (genero.isEmpty || genero == 'No especificado') {
      faltantes.add('Género');
    }
    if (alergias == 'Ninguna' && condiciones == 'Ninguna') {
      faltantes.add('Alergias o diagnósticos');
    }

    return faltantes;
  }
}
