import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keySession = 'session_token';
const _keyRole = 'user_role';

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  // ── Session ──────────────────────────────────────────────────────────────

  Future<void> saveSession(String token) =>
      _storage.write(key: _keySession, value: token);

  Future<String?> getSession() => _storage.read(key: _keySession);

  Future<void> deleteSession() => _storage.delete(key: _keySession);

  // ── Role ─────────────────────────────────────────────────────────────────

  Future<void> saveRole(String role) =>
      _storage.write(key: _keyRole, value: role);

  Future<String?> getRole() => _storage.read(key: _keyRole);

  // ── Convenience ──────────────────────────────────────────────────────────

  /// Removes all stored credentials.
  Future<void> clearAll() => _storage.deleteAll();
}
