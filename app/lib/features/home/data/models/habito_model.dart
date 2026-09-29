import 'package:freezed_annotation/freezed_annotation.dart';

part 'habito_model.freezed.dart';
part 'habito_model.g.dart';

@freezed
class Habito with _$Habito {
  const Habito._();

  const factory Habito({
    required String id,
    @JsonKey(name: 'usuario_id') required String usuarioId,
    required String tipo,
    required int meta,
    @JsonKey(name: 'progreso_actual') required int progresoActual,
    required DateTime fecha,
  }) = _Habito;

  double get porcentaje => meta == 0 ? 0 : progresoActual / meta;

  factory Habito.fromJson(Map<String, dynamic> json) =>
      _$HabitoFromJson(json);
}
