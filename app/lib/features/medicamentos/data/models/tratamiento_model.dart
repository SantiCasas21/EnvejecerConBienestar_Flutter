import 'package:freezed_annotation/freezed_annotation.dart';
import 'medicamento_model.dart';

part 'tratamiento_model.freezed.dart';
part 'tratamiento_model.g.dart';

@freezed
class TratamientoModel with _$TratamientoModel {
  const TratamientoModel._();

  const factory TratamientoModel({
    required dynamic id,
    required String diagnostico,
    @JsonKey(name: 'especialidad_medica', defaultValue: 'Medicina General') @Default('Medicina General') String? especialidadMedica,
    @JsonKey(name: 'medico_tratante') String? medicoTratante,
    @JsonKey(name: 'institucion_salud') String? institucionSalud,
    @JsonKey(name: 'fecha_inicio') String? fechaInicio,
    @JsonKey(name: 'fecha_fin') String? fechaFin,
    @JsonKey(name: 'es_cronico', defaultValue: false) bool? esCronico,
    @Default('activo') String estado, // 'activo', 'completado', 'suspendido'
    @JsonKey(name: 'objetivo_terapeutico') String? objetivoTerapeutico,
    @JsonKey(name: 'notas_evolucion') String? notasEvolucion,
    String? recomendaciones,
    @JsonKey(name: 'fecha_ultima_revision') String? fechaUltimaRevision,
    @JsonKey(name: 'proxima_cita') String? proximaCita,
    String? instrucciones,
    @Default('#0D9488') String color,
    @JsonKey(name: 'dias_transcurridos', defaultValue: 0) int? diasTranscurridos,
    @JsonKey(name: 'dias_totales', defaultValue: 0) int? diasTotales,
    @JsonKey(name: 'progreso_dias', defaultValue: 100.0) double? progresoDias,
    @JsonKey(name: 'adherencia_porcentaje', defaultValue: 100.0) @Default(100.0) double? adherenciaPorcentaje,
    @JsonKey(name: 'total_medicamentos', defaultValue: 0) int? totalMedicamentos,
    @Default([]) List<Medicamento> medicamentos,
  }) = _TratamientoModel;

  factory TratamientoModel.fromJson(Map<String, dynamic> json) =>
      _$TratamientoModelFromJson(json);

  bool get esActivo => estado == 'activo';
  bool get esCompletado => estado == 'completado';
  bool get esSuspendido => estado == 'suspendido';

  String get textoProgreso {
    if (esCronico == true) {
      return 'Tratamiento Permanente';
    }
    final actual = (diasTranscurridos ?? 0) + 1;
    final total = diasTotales ?? 0;
    if (total <= 0) return 'Tratamiento en curso';
    return 'Día $actual de $total';
  }

  String get textoEstado {
    switch (estado) {
      case 'completado':
        return 'Finalizado';
      case 'suspendido':
        return 'Suspendido';
      case 'activo':
      default:
        return 'En curso';
    }
  }
}
