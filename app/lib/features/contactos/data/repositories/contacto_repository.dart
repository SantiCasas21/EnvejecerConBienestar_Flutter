import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:envejecer_con_bienestar/core/network/api_client.dart';
import '../models/contacto_model.dart';

part 'contacto_repository.g.dart';

class ContactoRepository {
  final Dio _dio;

  ContactoRepository(this._dio);

  Future<List<Contacto>> getContactos() async {
    final response = await _dio.get('/contactos');
    return (response.data as List).map((json) => Contacto.fromJson(json)).toList();
  }

  Future<Contacto> getContacto(int id) async {
    final response = await _dio.get('/contactos/$id');
    return Contacto.fromJson(response.data);
  }

  Future<Contacto> createContacto(Map<String, dynamic> data) async {
    final response = await _dio.post('/contactos', data: data);
    return Contacto.fromJson(response.data);
  }

  Future<Contacto> updateContacto(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/contactos/$id', data: data);
    return Contacto.fromJson(response.data);
  }

  Future<void> deleteContacto(int id) async {
    await _dio.delete('/contactos/$id');
  }

  Future<List<Contacto>> getContactosEmergencia() async {
    final response = await _dio.get('/contactos/emergencia');
    return (response.data as List).map((json) => Contacto.fromJson(json)).toList();
  }
}

@riverpod
ContactoRepository contactoRepository(Ref ref) {
  return ContactoRepository(ref.watch(apiClientProvider));
}
