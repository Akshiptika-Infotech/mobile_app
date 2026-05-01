import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keySession = 'session_token';
const _keyRole = 'user_role';
const _keySessionExpires = 'session_expires';
const _keyRoleUpdatedAt = 'user_role_updated_at';

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

  // ── Session Expiry ───────────────────────────────────────────────────────

  /// Stores the ISO-8601 expiry timestamp from the NextAuth session.
  Future<void> saveSessionExpires(DateTime expires) =>
      _storage.write(key: _keySessionExpires, value: expires.toIso8601String());

  Future<DateTime?> getSessionExpires() async {
    final raw = await _storage.read(key: _keySessionExpires);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> deleteSessionExpires() =>
      _storage.delete(key: _keySessionExpires);

  // ── Role Change Detection ────────────────────────────────────────────────

  /// Stores a timestamp indicating when the cached role was last verified.
  /// In future this can be compared against a backend `user.updatedAt` field.
  Future<void> saveRoleUpdatedAt(DateTime updatedAt) =>
      _storage.write(key: _keyRoleUpdatedAt, value: updatedAt.toIso8601String());

  Future<DateTime?> getRoleUpdatedAt() async {
    final raw = await _storage.read(key: _keyRoleUpdatedAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ── Convenience ──────────────────────────────────────────────────────────

  /// Removes all stored credentials.
  Future<void> clearAll() => _storage.deleteAll();
}
