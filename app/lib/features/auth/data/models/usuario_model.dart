import 'package:freezed_annotation/freezed_annotation.dart';

part 'usuario_model.freezed.dart';
part 'usuario_model.g.dart';

@freezed
class UsuarioModel with _$UsuarioModel {
  const UsuarioModel._();

  const factory UsuarioModel({
    required int id,
    required String nombre,
    required String email,
    @Default('adulto_mayor') String rol,
    @JsonKey(name: 'codigo_vinculacion') String? codigoVinculacion,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UsuarioModel;

  factory UsuarioModel.fromJson(Map<String, dynamic> json) =>
      _$UsuarioModelFromJson(json);

  bool get esCuidador => rol == 'cuidador';
  bool get esAdultoMayor => rol != 'cuidador';
}
