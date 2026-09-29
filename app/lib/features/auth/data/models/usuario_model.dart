import 'package:freezed_annotation/freezed_annotation.dart';

part 'usuario_model.freezed.dart';
part 'usuario_model.g.dart';

@freezed
class UsuarioModel with _$UsuarioModel {
  const factory UsuarioModel({
    required int id,
    required String nombre,
    required String email,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UsuarioModel;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) =>
      _$UsuarioModelFromJson(json);
}
