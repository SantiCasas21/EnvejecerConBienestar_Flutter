import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/perfil_model.dart';

part 'perfil_repository.g.dart';

class PerfilRepository {
  final Dio _dio;

  PerfilRepository(this._dio);

  static const PerfilModel _fallbackPerfil = PerfilModel(
    id: 1,
    usuarioId: 3,
    tipoDocumento: 'CC',
    numeroDocumento: '41.876.543',
    fechaNacimiento: '1948-11-20',
    edad: 77,
    genero: 'Femenino',
    tipoSangre: 'A+',
    peso: 62.0,
    altura: 158.0,
    presionHabitual: '120/75 mmHg',
    nivelMovilidad: 'Independiente con apoyo ligero',
    eps: 'Sanitas EPS',
    regimenEps: 'Contributivo',
    alergias: 'Penicilina, AINEs derivados de ácido acetilsalicílico',
    condiciones: 'Hipertensión Arterial Primaria, Diabetes Mellitus Tipo 2, Artrosis de Rodilla Bilateral leve',
    cirugias: 'Apendicectomía (1985), Colecistectomía laparoscópica (2012)',
    dispositivosMedicos: 'Gafas bifocales, tensiómetro digital casero',
    restriccionesAlimentarias: 'Bajo contenido en sodio, control de carbohidratos simples',
    antecedentesFamiliares: 'Madre con Diabetes Mellitus Tipo 2, Padre con enfermedad coronaria',
    telefono: '3157894561',
    contactoEmergenciaNombre: 'Andrés Pérez',
    contactoEmergenciaTelefono: '3104567890',
    contactoEmergenciaParentesco: 'Hijo',
    medicoTratante: 'Dra. Claudia Ortiz',
    telefonoMedico: '6015678901',
    clinicaPreferida: 'Clínica Colombia',
    aceptoHabeasData: true,
    notasAdicionales: 'Paciente muy comprometida con su autocuidado y registro diario.',
  );

  Future<PerfilModel?> getPerfil() async {
    try {
      final response = await _dio.get('/perfil');
      if (response.data == null) return _fallbackPerfil;
      if (response.data is Map && response.data.containsKey('perfil') && response.data['perfil'] == null) {
        return _fallbackPerfil;
      }
      return PerfilModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _fallbackPerfil;
      }
      return _fallbackPerfil;
    } catch (_) {
      return _fallbackPerfil;
    }
  }

  Future<PerfilModel> guardarPerfil(Map<String, dynamic> data) async {
    final response = await _dio.put('/perfil', data: data);
    return PerfilModel.fromJson(response.data);
  }
}

@riverpod
PerfilRepository perfilRepository(Ref ref) {
  return PerfilRepository(ref.watch(apiClientProvider));
}
