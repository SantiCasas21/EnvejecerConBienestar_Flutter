import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'secure_storage_service.g.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  // Caché en memoria para lecturas instantáneas (0ms) en cada petición HTTP
  String? _memAccessToken;
  String? _memRefreshToken;
  String? _memUserJson;

  SecureStorageService(this._storage);

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserJson = 'cached_user_json';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _memAccessToken = accessToken;
    _memRefreshToken = refreshToken;

    // Respaldo rápido en SharedPreferences para arranque instantáneo y persistencia en Web/Móvil
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
    } catch (_) {}

    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    if (_memAccessToken != null && _memAccessToken!.isNotEmpty) {
      return _memAccessToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefToken = prefs.getString(_keyAccessToken);
      if (prefToken != null && prefToken.isNotEmpty) {
        _memAccessToken = prefToken;
        return prefToken;
      }
    } catch (_) {}

    try {
      final token = await _storage.read(key: _keyAccessToken);
      if (token != null && token.isNotEmpty) {
        _memAccessToken = token;
        return token;
      }
    } catch (_) {}

    return null;
  }

  Future<String?> getRefreshToken() async {
    if (_memRefreshToken != null && _memRefreshToken!.isNotEmpty) {
      return _memRefreshToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefToken = prefs.getString(_keyRefreshToken);
      if (prefToken != null && prefToken.isNotEmpty) {
        _memRefreshToken = prefToken;
        return prefToken;
      }
    } catch (_) {}

    try {
      final token = await _storage.read(key: _keyRefreshToken);
      if (token != null && token.isNotEmpty) {
        _memRefreshToken = token;
        return token;
      }
    } catch (_) {}

    return null;
  }

  Future<void> saveUserJson(String userJson) async {
    _memUserJson = userJson;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserJson, userJson);
    } catch (_) {}
  }

  Future<String?> getUserJson() async {
    if (_memUserJson != null && _memUserJson!.isNotEmpty) {
      return _memUserJson;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyUserJson);
      if (raw != null && raw.isNotEmpty) {
        _memUserJson = raw;
        return raw;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearTokens() async {
    _memAccessToken = null;
    _memRefreshToken = null;
    _memUserJson = null;

    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserJson);
    } catch (_) {}
  }
}

@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService(
    const FlutterSecureStorage(
      webOptions: WebOptions(
        dbName: 'ecb_secure_vault',
        publicKey: 'ecb_key',
      ),
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ),
  );
}
