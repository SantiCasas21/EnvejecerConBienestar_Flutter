import 'package:freezed_annotation/freezed_annotation.dart';

part 'contacto_model.freezed.dart';
part 'contacto_model.g.dart';

@freezed
class Contacto with _$Contacto {
  const factory Contacto({
    required dynamic id,
    required String nombre,
    required String telefono,
    @Default('') String ubicacion,
    @Default('') String categoria,
    @Default('👤') String icono,
    @JsonKey(name: 'es_favorito', defaultValue: false) @Default(false) bool esFavorito,
    @JsonKey(name: 'es_emergencia', defaultValue: false) @Default(false) bool esEmergencia,
  }) = _Contacto;

  factory Contacto.fromJson(Map<String, dynamic> json) =>
      _$ContactoFromJson(json);
}
