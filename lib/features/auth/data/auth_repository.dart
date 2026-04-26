import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Authenticates with NextAuth credentials provider.
  ///
  /// Returns the [UserModel] on success, throws [AuthException] on failure.
  Future<UserModel> login(String email, String password) async {
    try {
      // Step 1: Obtain CSRF token required by NextAuth.
      final csrfResponse = await _dio.get('/api/auth/csrf');
      final csrfData = csrfResponse.data as Map<String, dynamic>?;
      final csrfToken = csrfData?['csrfToken'] as String?;

      // Step 2: POST credentials.
      await _dio.post(
        '/api/auth/callback/credentials',
        data: {
          'email': email,
          'password': password,
          if (csrfToken != null) 'csrfToken': csrfToken,
          'callbackUrl': '/',
          'json': 'true',
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );

      // Step 3: Fetch the session to get the user object.
      final user = await getSession();
      if (user == null) {
        throw const AuthException('Login failed: invalid credentials.');
      }
      return user;
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// Fetches the current NextAuth session.
  Future<UserModel?> getSession() async {
    try {
      final response = await _dio.get('/api/auth/session');
      final data = response.data as Map<String, dynamic>?;
      if (data == null || data.isEmpty || data['user'] == null) return null;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// Changes the password for the currently authenticated user.
  ///
  /// The backend exposes a role-specific PATCH endpoint
  /// (`/api/{role}/profile`) that accepts `{currentPassword, newPassword}`.
  Future<void> changePassword({
    required String role,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.patch(
        _profilePathForRole(role),
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  /// Maps a session role to its backend profile endpoint.
  static String _profilePathForRole(String role) {
    switch (role) {
      case 'DRIVER':
        return '/api/driver/profile';
      case 'PARENT':
        return '/api/parent/profile';
      case 'STUDENT':
        return '/api/student/profile';
      case 'SECURITY_GUARD':
        return '/api/security/profile';
      case 'RECEPTIONIST':
        return '/api/reception/profile';
      // SUPER_ADMIN / ADMIN / CLERK / TEACHER / WEB_ADMIN all share the admin profile
      default:
        return '/api/admin/profile';
    }
  }

  /// Signs out the current user.
  Future<void> logout() async {
    try {
      // Obtain CSRF token first.
      final csrfResponse = await _dio.get('/api/auth/csrf');
      final csrfData = csrfResponse.data as Map<String, dynamic>?;
      final csrfToken = csrfData?['csrfToken'] as String?;

      await _dio.post(
        '/api/auth/signout',
        data: {
          if (csrfToken != null) 'csrfToken': csrfToken,
          'callbackUrl': '/',
          'json': 'true',
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
    } on DioException catch (e) {
      throw AuthException(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      return (data['message'] ?? data['error'] ?? e.message).toString();
    }
    return e.message ?? 'An unexpected error occurred.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
