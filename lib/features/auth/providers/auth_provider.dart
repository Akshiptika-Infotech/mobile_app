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
  Future<void> _checkSession() async {
    state = const AuthLoading();
    try {
      final token = await _storage.getSession();
      if (token == null) {
        state = const AuthUnauthenticated();
        return;
      }
      final user = await _repository.getSession();
      if (user != null) {
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

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
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
