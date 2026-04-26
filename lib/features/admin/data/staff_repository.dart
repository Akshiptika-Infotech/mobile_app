import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/user_staff_model.dart';

class StaffRepository {
  StaffRepository(this._dio);
  final Dio _dio;

  Future<List<StaffUser>> fetchUsers() async {
    final res = await _dio.get('/api/admin/users');
    final data = res.data;
    final list = _extractList(data);
    return list
        .map((e) => StaffUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StaffUser> createUser(Map<String, dynamic> data) async {
    final res = await _dio.post('/api/admin/users', data: data);
    return StaffUser.fromJson(_extractItem(res.data));
  }

  Future<StaffUser> updateUser(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/api/admin/users/$id', data: data);
    return StaffUser.fromJson(_extractItem(res.data));
  }

  Future<void> deleteUser(String id) async {
    await _dio.delete('/api/admin/users/$id');
  }

  /// Resets a staff/user password to a default value and returns the
  /// plain-text password so the admin can share it. The backend has no
  /// dedicated reset endpoint — it accepts `{password}` on PATCH and
  /// hashes it server-side.
  Future<String> resetPassword(String id, {String? newPassword}) async {
    final pwd = newPassword?.trim().isNotEmpty == true
        ? newPassword!.trim()
        : 'changeme123';
    await _dio.patch('/api/admin/users/$id', data: {'password': pwd});
    return pwd;
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'users', 'staff']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }

  static Map<String, dynamic> _extractItem(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'user', 'staff']) {
        if (data[key] is Map<String, dynamic>) {
          return data[key] as Map<String, dynamic>;
        }
      }
      return data;
    }
    return {};
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(dioClientProvider));
});
