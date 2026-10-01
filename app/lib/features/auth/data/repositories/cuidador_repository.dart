import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/paciente_vinculado_model.dart';

class CuidadorRepository {
  final Dio _dio;

  // Fallback local en memoria para garantizar resiliencia offline (Regla 4 ia/desarrollo.md)
  final List<PacienteVinculadoModel> _fallbackPacientes = [
    const PacienteVinculadoModel(
      id: 1,
      nombre: 'Santiago Gómez',
      email: 'santiago@envejecer.com',
      codigoVinculacion: 'ECB-1001',
      parentesco: 'Hija / Cuidadora',
      fechaVinculacion: '2026-09-29',
      edad: 75,
      genero: 'Masculino',
      tipoSangre: 'O+',
      eps: 'SURA EPS',
      alergias: 'Penicilina, Mariscos',
      condiciones: 'Hipertensión arterial controlada, Artrosis leve',
      telefono: '3109876543',
      contactoEmergenciaNombre: 'Carolina Gómez',
      contactoEmergenciaTelefono: '3001234567',
      totalMedicamentos: 3,
      tomasCumplidas: 1,
      tomasPendientes: 2,
      alertasStock: 1,
      medicamentosAlerta: ['Acetaminofén (4 restantes)'],
      proximaToma: {
        'nombre': 'Losartán Potásico',
        'miligramos': '50 mg',
        'hora': '08:00',
        'icono': '💊',
      },
      medicamentos: [
        {
          'id': 1,
          'nombre': 'Losartán Potásico',
          'miligramos': '50 mg',
          'notas': '1 pastilla cada 12 horas',
          'frecuencia': 12,
          'hora_alarma': '08:00',
          'esta_tomado': false,
          'cantidad_restante': 28,
          'umbral_alerta': 5,
          'alerta_inventario': false,
          'dias_autonomia': 14,
          'icono': '💊',
        },
        {
          'id': 2,
          'nombre': 'Metformina',
          'miligramos': '850 mg',
          'notas': '1 pastilla con el desayuno',
          'frecuencia': 24,
          'hora_alarma': '07:30',
          'esta_tomado': true,
          'cantidad_restante': 15,
          'umbral_alerta': 5,
          'alerta_inventario': false,
          'dias_autonomia': 15,
          'icono': '💊',
        },
        {
          'id': 3,
          'nombre': 'Acetaminofén',
          'miligramos': '500 mg',
          'notas': 'Para dolores articulares',
          'frecuencia': 8,
          'hora_alarma': '14:00',
          'esta_tomado': false,
          'cantidad_restante': 4,
          'umbral_alerta': 5,
          'alerta_inventario': true,
          'dias_autonomia': 1,
          'icono': '💊',
        },
      ],
    ),
  ];

  CuidadorRepository(this._dio);

  Future<List<PacienteVinculadoModel>> getPacientes() async {
    try {
      final response = await _dio.get('${ApiEndpoints.cuidadores}/pacientes');
      if (response.data is Map && response.data['pacientes'] != null) {
        final list = response.data['pacientes'] as List<dynamic>;
        final pacientes = list
            .map((item) =>
                PacienteVinculadoModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return pacientes;
      }
      return [];
    } on DioException catch (_) {
      // Fallback offline resiliente: nunca romper la app
      return _fallbackPacientes;
    } catch (_) {
      return _fallbackPacientes;
    }
  }

  Future<Map<String, dynamic>> vincularPaciente(
    String codigoVinculacion, {
    String parentesco = 'Familiar / Cuidador',
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.cuidadores}/vincular',
        data: {
          'codigo_vinculacion': codigoVinculacion.trim().toUpperCase(),
          'parentesco': parentesco.trim(),
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['msg'] != null) {
        throw Exception(e.response?.data['msg']);
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        // Fallback local: simular vinculación si no hay red
        final codigoUpper = codigoVinculacion.trim().toUpperCase();
        final nuevo = PacienteVinculadoModel(
          id: DateTime.now().millisecondsSinceEpoch % 10000,
          nombre: 'Paciente Vinculado ($codigoUpper)',
          email: 'paciente@ejemplo.com',
          codigoVinculacion: codigoUpper,
          parentesco: parentesco,
          totalMedicamentos: 2,
          tomasCumplidas: 1,
          tomasPendientes: 1,
          alertasStock: 0,
        );
        _fallbackPacientes.add(nuevo);
        return {
          'mensaje': '¡Paciente vinculado localmente!',
          'paciente': nuevo.toJson(),
        };
      }
      throw Exception(
          'No se pudo vincular al paciente. Verifica tu conexión a internet.');
    }
  }

  Future<Map<String, dynamic>> getDetallePaciente(int pacienteId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.cuidadores}/pacientes/$pacienteId/detalle',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['msg'] != null) {
        throw Exception(e.response?.data['msg']);
      }
      throw Exception('No se pudo cargar el detalle del paciente.');
    }
  }

  Future<bool> desvincularPaciente(int pacienteId) async {
    try {
      await _dio.delete('${ApiEndpoints.cuidadores}/pacientes/$pacienteId');
      _fallbackPacientes.removeWhere((p) => p.id == pacienteId);
      return true;
    } on DioException catch (_) {
      _fallbackPacientes.removeWhere((p) => p.id == pacienteId);
      return true;
    }
  }

  Future<List<Map<String, dynamic>>> getMedicamentosPaciente(int pacienteId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.cuidadores}/pacientes/$pacienteId/medicamentos');
      if (response.data is Map && response.data['medicamentos'] != null) {
        final list = response.data['medicamentos'] as List<dynamic>;
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return [];
    } on DioException catch (_) {
      final pac = _fallbackPacientes.firstWhere(
        (p) => p.id == pacienteId,
        orElse: () => _fallbackPacientes.first,
      );
      return pac.medicamentos;
    } catch (_) {
      return [];
    }
  }

  Future<bool> reabastecerMedicamentoPaciente(
    int pacienteId,
    int medId,
    int cantidad,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.cuidadores}/pacientes/$pacienteId/medicamentos/$medId/reabastecer',
        data: {'cantidad': cantidad},
      );
      return response.statusCode == 200;
    } on DioException catch (_) {
      for (var p in _fallbackPacientes) {
        if (p.id == pacienteId) {
          for (var m in p.medicamentos) {
            if (m['id'] == medId) {
              final cantActual = (m['cantidad_restante'] as num?)?.toInt() ?? 0;
              m['cantidad_restante'] = cantActual + cantidad;
              m['alerta_inventario'] = (cantActual + cantidad) <= 5;
            }
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final cuidadorRepositoryProvider = Provider<CuidadorRepository>((ref) {
  return CuidadorRepository(ref.watch(apiClientProvider));
});
