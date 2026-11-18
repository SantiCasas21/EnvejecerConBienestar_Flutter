import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_contacts/flutter_contacts.dart';

/// Resultado de lectura de contactos nativos del teléfono.
class PhoneContactsResult {
  final List<Contact> contactos;
  final bool permisoDenegado;
  final bool permisoPermanente;
  final bool noDisponibleEnPlataforma;

  const PhoneContactsResult({
    this.contactos = const [],
    this.permisoDenegado = false,
    this.permisoPermanente = false,
    this.noDisponibleEnPlataforma = false,
  });
}

class PhoneContactsService {
  /// Abre el selector nativo del sistema para elegir un solo contacto.
  static Future<Contact?> seleccionarContacto() async {
    if (kIsWeb) return null;
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        return null;
      }
      return await FlutterContacts.native.showPicker(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.address,
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Obtiene todos los contactos con teléfono de la agenda del dispositivo.
  static Future<PhoneContactsResult> obtenerContactosDelTelefono() async {
    if (kIsWeb) {
      return const PhoneContactsResult(noDisponibleEnPlataforma: true);
    }
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status == PermissionStatus.permanentlyDenied ||
          status == PermissionStatus.restricted) {
        return const PhoneContactsResult(
          permisoDenegado: true,
          permisoPermanente: true,
        );
      }
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        return const PhoneContactsResult(permisoDenegado: true);
      }

      final todos = await FlutterContacts.getAll(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.address,
        },
      );

      final conTelefono = todos
          .where((c) =>
              (c.displayName ?? '').trim().isNotEmpty && c.phones.isNotEmpty)
          .toList()
        ..sort((a, b) => (a.displayName ?? '')
            .toLowerCase()
            .compareTo((b.displayName ?? '').toLowerCase()));

      return PhoneContactsResult(contactos: conTelefono);
    } catch (_) {
      return const PhoneContactsResult(noDisponibleEnPlataforma: true);
    }
  }

  /// Abre los ajustes de permisos si el usuario denegó permanentemente.
  static Future<void> abrirAjustesPermisos() async {
    if (kIsWeb) return;
    try {
      await FlutterContacts.permissions.openSettings();
    } catch (_) {}
  }
}
