import 'package:freezed_annotation/freezed_annotation.dart';

part 'meta_model.freezed.dart';
part 'meta_model.g.dart';

@freezed
class MetaModel with _$MetaModel {
  const MetaModel._();

  const factory MetaModel({
    required int id,
    @JsonKey(name: 'usuario_id') required int usuarioId,
    required String nombre,
    @Default(1) int objetivo,
    @Default(0) int progreso,
    @Default('vasos') String unidad,
    @Default('🎯') String icono,
    @JsonKey(name: 'fecha_inicio') String? fechaInicio,
    @JsonKey(name: 'fecha_fin') String? fechaFin,
    @Default(false) bool completada,
  }) = _MetaModel;

  double get porcentaje => objetivo == 0 ? 0 : (progreso / objetivo).clamp(0.0, 1.0);

  String obtenerMensajeMotivacional() {
    if (completada || porcentaje >= 1.0) {
      final mensajesExito = [
        '🎉 ¡Extraordinario logro! Tu esfuerzo diario construye una vida llena de bienestar.',
        '🌟 ¡Meta cumplida! Cada paso constante que das inspira salud y vitalidad.',
        '💪 ¡Excelente disciplina! Mantener tus metas activas fortalece tu cuerpo y mente.',
        '🏆 ¡Bravo! Celebrar estos pequeños triunfos diarios es la clave del envejecimiento activo.'
      ];
      return mensajesExito[id % mensajesExito.length];
    } else if (porcentaje >= 0.5) {
      return '🚀 ¡Vas a más de la mitad! Continúa con esa excelente energía.';
    } else if (progreso > 0) {
      return '🌱 ¡Buen inicio! Cada acción cuenta para lograr tu objetivo de hoy.';
    } else {
      return '☀️ ¡Hoy es un gran día para avanzar hacia tu bienestar!';
    }
  }

  factory MetaModel.fromJson(Map<String, dynamic> json) =>
      _$MetaModelFromJson(json);
}
