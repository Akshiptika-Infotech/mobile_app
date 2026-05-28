import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/storage/secure_storage.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, this._storage) : super(const AuthInitial()) {
    _checkSession();
  }

  final AuthRepository _repository;
  final SecureStorageService _storage;

  /// Checks existing session on startup.
  /// Validates expiry and role consistency before emitting [AuthAuthenticated].
  Future<void> _checkSession() async {
    state = const AuthLoading();
    try {
      final token = await _storage.getSession();
      if (token == null) {
        state = const AuthUnauthenticated();
        return;
      }

      // Check cached expiry before making a network call.
      final expires = await _storage.getSessionExpires();
      if (expires != null && DateTime.now().isAfter(expires)) {
        await _storage.clearAll();
        state = const AuthUnauthenticated();
        return;
      }

      final user = await _repository.getSession();
      if (user != null) {
        // Role mismatch guard: if the backend role differs from cached role,
        // force a clean re-authentication.
        final cachedRole = await _storage.getRole();
        if (cachedRole != null && cachedRole != user.role) {
          await _storage.clearAll();
          state = const AuthUnauthenticated();
          return;
        }

        // Persist refreshed expiry if the backend returned one.
        if (user.expires != null) {
          await _storage.saveSessionExpires(user.expires!);
        }
        state = AuthAuthenticated(user);
      } else {
        await _storage.clearAll();
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(email, password);
      await _storage.saveSession('session');
      await _storage.saveRole(user.role);
      if (user.expires != null) {
        await _storage.saveSessionExpires(user.expires!);
      }
      await _storage.saveRoleUpdatedAt(DateTime.now());
      state = AuthAuthenticated(user);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _repository.logout();
    } catch (_) {
      // best-effort logout
    } finally {
      await _storage.clearAll();
      state = const AuthUnauthenticated();
    }
  }

  /// Proactively validates the session when the app resumes from background.
  /// If the session has expired, emits [AuthUnauthenticated] gracefully.
  /// If the session is near expiry (within 24h), attempts a refresh first.
  Future<void> validateSession() async {
    final current = state;
    if (current is! AuthAuthenticated) return;

    try {
      final expires = await _storage.getSessionExpires();
      final now = DateTime.now();

      // If already expired → force logout.
      if (expires != null && now.isAfter(expires)) {
        await logout();
        return;
      }

      // If near expiry (within 24 hours) → try backend refresh.
      final nearExpiry = expires != null &&
          expires.difference(now).inHours < 24;

      UserModel? refreshed;
      if (nearExpiry) {
        refreshed = await _repository.refreshSession();
      } else {
        refreshed = await _repository.getSession();
      }

      if (refreshed == null) {
        await logout();
        return;
      }

      // Role mismatch guard on resume.
      final cachedRole = await _storage.getRole();
      if (cachedRole != null && cachedRole != refreshed.role) {
        await logout();
        return;
      }

      if (refreshed.expires != null) {
        await _storage.saveSessionExpires(refreshed.expires!);
      }
      state = AuthAuthenticated(refreshed);
    } catch (_) {
      // Network error on resume is non-fatal; keep current state.
      // The next API call will trigger the 401 interceptor if truly expired.
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  /// Updates the cached user's avatar in-memory after a successful upload.
  /// Pass `null` to clear it.
  void updateUserImage(String? imageUrl) {
    final current = state;
    if (current is! AuthAuthenticated) return;
    state = AuthAuthenticated(
      current.user.copyWith(image: imageUrl, clearImage: imageUrl == null),
    );
  }

  /// Clears the `mustChangePassword` flag in-memory after the user has
  /// successfully rotated their password. The backend has already set the
  /// DB column to `false` — this just lets the router redirect logic move
  /// the user into their portal without a full session refetch.
  void clearMustChangePassword() {
    final current = state;
    if (current is! AuthAuthenticated) return;
    state = AuthAuthenticated(
      current.user.copyWith(mustChangePassword: false),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repository, storage);
});

/// Convenience provider: returns the authenticated user or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.user;
  return null;
});
