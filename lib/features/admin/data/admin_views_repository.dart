import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';

class AdminViewsRepository {
  AdminViewsRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchList(String path) async {
    final res = await _dio.get(path);
    final list = _extractList(res.data);
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> patch(String path, Map<String, dynamic> data) async {
    await _dio.patch(path, data: data);
  }

  Future<void> post(String path, Map<String, dynamic> data) async {
    await _dio.post(path, data: data);
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in [
        'data',
        'items',
        'results',
        'records',
        'visitors',
        'passes',
        'logs',
        'calls',
        'appointments',
        'arrivals',
        'students',
        'staff',
        'leaves',
        'certificates',
        'idCards'
      ]) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final adminViewsRepositoryProvider = Provider<AdminViewsRepository>((ref) {
  return AdminViewsRepository(ref.watch(dioClientProvider));
});
