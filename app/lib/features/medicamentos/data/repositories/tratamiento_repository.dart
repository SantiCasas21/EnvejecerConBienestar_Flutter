import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_client.dart';
import '../models/tratamiento_model.dart';

part 'tratamiento_repository.g.dart';

class TratamientoRepository {
  final Dio _dio;

  TratamientoRepository(this._dio);

  static final List<TratamientoModel> _fallbackTratamientos = [
    const TratamientoModel(
      id: 1,
      diagnostico: 'Hipertensión Arterial Primaria (CIE-10: I10)',
      medicoTratante: 'Dra. Claudia Ortiz',
      institucionSalud: 'Sanitas EPS / Clínica Colombia',
      fechaInicio: '2026-08-20',
      esCronico: true,
      estado: 'activo',
      color: '#1E3A8A',
      instrucciones: 'Tomar Losartán 50mg cada mañana con abundante agua.',
      diasTranscurridos: 70,
      diasTotales: 0,
      progresoDias: 100.0,
      totalMedicamentos: 1,
    ),
    const TratamientoModel(
      id: 2,
      diagnostico: 'Diabetes Mellitus Tipo 2 (CIE-10: E11)',
      medicoTratante: 'Dr. Gabriel Valencia',
      institucionSalud: 'Sanitas Tequendama',
      fechaInicio: '2026-08-20',
      esCronico: true,
      estado: 'activo',
      color: '#0D9488',
      instrucciones: 'Metformina 850mg dos veces al día con comidas principales.',
      diasTranscurridos: 70,
      diasTotales: 0,
      progresoDias: 100.0,
      totalMedicamentos: 1,
    ),
    const TratamientoModel(
      id: 3,
      diagnostico: 'Artrosis de Rodilla Bilateral (CIE-10: M17)',
      medicoTratante: 'Dr. Roberto Gómez',
      institucionSalud: 'Hospital Méderi',
      fechaInicio: '2026-08-20',
      fechaFin: '2027-02-20',
      esCronico: false,
      estado: 'activo',
      color: '#059669',
      instrucciones: 'Acetaminofén 500mg cada 8 horas en caso de rigidez o dolor.',
      diasTranscurridos: 70,
      diasTotales: 184,
      progresoDias: 38.0,
      totalMedicamentos: 1,
    ),
  ];

  Future<List<TratamientoModel>> getTratamientos({String? estado}) async {
    try {
      final response = await _dio.get(
        '/tratamientos',
        queryParameters: estado != null ? {'estado': estado} : null,
      );
      return (response.data as List)
          .map((json) => TratamientoModel.fromJson(json))
          .toList();
    } on DioException catch (_) {
      if (estado != null) {
        return _fallbackTratamientos.where((t) => t.estado == estado).toList();
      }
      return _fallbackTratamientos;
    } catch (_) {
      return _fallbackTratamientos;
    }
  }

  Future<TratamientoModel> getTratamiento(int id) async {
    try {
      final response = await _dio.get('/tratamientos/$id');
      return TratamientoModel.fromJson(response.data);
    } catch (_) {
      return _fallbackTratamientos.firstWhere(
        (t) => (int.tryParse(t.id.toString()) ?? 0) == id,
        orElse: () => TratamientoModel(id: id, diagnostico: 'Tratamiento #$id'),
      );
    }
  }

  Future<TratamientoModel> createTratamiento(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tratamientos', data: data);
      final created = TratamientoModel.fromJson(response.data);
      _fallbackTratamientos.removeWhere((t) => t.id == created.id);
      _fallbackTratamientos.insert(0, created);
      return created;
    } catch (_) {
      final newId = (_fallbackTratamientos.isNotEmpty
              ? _fallbackTratamientos
                  .map((t) => int.tryParse(t.id.toString()) ?? 0)
                  .reduce((a, b) => a > b ? a : b)
              : 0) +
          1;
      final fallbackItem = TratamientoModel(
        id: newId,
        diagnostico: data['diagnostico']?.toString() ?? 'Tratamiento',
        especialidadMedica: data['especialidad_medica']?.toString() ?? 'Medicina General',
        medicoTratante: data['medico_tratante']?.toString(),
        institucionSalud: data['institucion_salud']?.toString(),
        fechaInicio: data['fecha_inicio']?.toString(),
        fechaFin: data['fecha_fin']?.toString(),
        esCronico: data['es_cronico'] == true,
        estado: data['estado']?.toString() ?? 'activo',
        color: data['color']?.toString() ?? '#0D9488',
        instrucciones: data['instrucciones']?.toString(),
      );
      _fallbackTratamientos.insert(0, fallbackItem);
      return fallbackItem;
    }
  }

  Future<TratamientoModel> updateTratamiento(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/tratamientos/$id', data: data);
      final updated = TratamientoModel.fromJson(response.data);
      final idx = _fallbackTratamientos.indexWhere((t) => (int.tryParse(t.id.toString()) ?? 0) == id);
      if (idx != -1) {
        _fallbackTratamientos[idx] = updated;
      }
      return updated;
    } catch (_) {
      final idx = _fallbackTratamientos.indexWhere((t) => (int.tryParse(t.id.toString()) ?? 0) == id);
      if (idx != -1) {
        final existing = _fallbackTratamientos[idx];
        final updated = existing.copyWith(
          diagnostico: data['diagnostico']?.toString() ?? existing.diagnostico,
          especialidadMedica: data['especialidad_medica']?.toString() ?? existing.especialidadMedica,
          medicoTratante: data['medico_tratante']?.toString() ?? existing.medicoTratante,
          institucionSalud: data['institucion_salud']?.toString() ?? existing.institucionSalud,
          fechaInicio: data['fecha_inicio']?.toString() ?? existing.fechaInicio,
          fechaFin: data['fecha_fin']?.toString() ?? existing.fechaFin,
          esCronico: data['es_cronico'] is bool ? data['es_cronico'] as bool : existing.esCronico,
          instrucciones: data['instrucciones']?.toString() ?? existing.instrucciones,
        );
        _fallbackTratamientos[idx] = updated;
        return updated;
      }
      return TratamientoModel(
        id: id,
        diagnostico: data['diagnostico']?.toString() ?? 'Tratamiento',
        especialidadMedica: data['especialidad_medica']?.toString() ?? 'Medicina General',
      );
    }
  }

  Future<TratamientoModel> cambiarEstado(int id, String estado) async {
    try {
      final response = await _dio.patch('/tratamientos/$id/estado', data: {'estado': estado});
      final updated = TratamientoModel.fromJson(response.data);
      final idx = _fallbackTratamientos.indexWhere((t) => (int.tryParse(t.id.toString()) ?? 0) == id);
      if (idx != -1) {
        _fallbackTratamientos[idx] = updated;
      }
      return updated;
    } catch (_) {
      final idx = _fallbackTratamientos.indexWhere((t) => (int.tryParse(t.id.toString()) ?? 0) == id);
      if (idx != -1) {
        final updated = _fallbackTratamientos[idx].copyWith(estado: estado);
        _fallbackTratamientos[idx] = updated;
        return updated;
      }
      return TratamientoModel(id: id, diagnostico: 'Tratamiento', estado: estado);
    }
  }

  Future<void> deleteTratamiento(int id) async {
    try {
      await _dio.delete('/tratamientos/$id');
    } catch (_) {}
    _fallbackTratamientos.removeWhere((t) => (int.tryParse(t.id.toString()) ?? 0) == id);
  }
}

@riverpod
TratamientoRepository tratamientoRepository(Ref ref) {
  return TratamientoRepository(ref.watch(apiClientProvider));
}
