import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/transport_model.dart';

class TransportAdminRepository {
  TransportAdminRepository(this._dio);
  final Dio _dio;

  // ── Routes ─────────────────────────────────────────────────────────────────

  Future<List<TransportRoute>> fetchRoutes() async {
    final res = await _dio.get('/api/admin/transport/routes');
    return _extractList(res.data)
        .map((e) => TransportRoute.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRoute(Map<String, dynamic> data) async {
    await _dio.post('/api/admin/transport/routes', data: data);
  }

  Future<void> deleteRoute(String id) async {
    await _dio.delete('/api/admin/transport/routes/$id');
  }

  // ── Assignments ────────────────────────────────────────────────────────────

  Future<List<TransportAssignment>> fetchAssignments() async {
    final res = await _dio.get('/api/admin/transport/assignments');
    return _extractList(res.data)
        .map((e) => TransportAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAssignment(Map<String, dynamic> data) async {
    await _dio.post('/api/admin/transport/assignments', data: data);
  }

  // ── Rebates ────────────────────────────────────────────────────────────────

  Future<List<TransportRebate>> fetchRebates() async {
    final res = await _dio.get('/api/admin/transport/rebates');
    return _extractList(res.data)
        .map((e) => TransportRebate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRebate(Map<String, dynamic> data) async {
    await _dio.post('/api/admin/transport/rebates', data: data);
  }

  Future<void> deleteRebate(String id) async {
    await _dio.delete('/api/admin/transport/rebates/$id');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'routes', 'assignments', 'rebates']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final transportAdminRepositoryProvider =
    Provider<TransportAdminRepository>((ref) {
  return TransportAdminRepository(ref.watch(dioClientProvider));
});
