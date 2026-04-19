import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';

class MastersRepository {
  MastersRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchMasters(String model) async {
    final res = await _dio.get('/api/admin/masters/$model');
    final data = res.data;
    final list = _extractList(data);
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> createMaster(String model, String name) async {
    await _dio.post('/api/admin/masters/$model', data: {'name': name});
  }

  Future<void> deleteMaster(String model, String id) async {
    await _dio.delete('/api/admin/masters/$model/$id');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'results']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final mastersRepositoryProvider = Provider<MastersRepository>((ref) {
  return MastersRepository(ref.watch(dioClientProvider));
});
