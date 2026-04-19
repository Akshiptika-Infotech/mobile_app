import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/fee_master_model.dart';

class FeeMasterRepository {
  FeeMasterRepository(this._dio);
  final Dio _dio;

  // ── Fee Types ──────────────────────────────────────────────────────────────

  Future<List<FeeType>> fetchFeeTypes() async {
    final res = await _dio.get('/api/admin/fee-masters/fee-types');
    return _extractList(res.data)
        .map((e) => FeeType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createFeeType(String name, String description, bool isOptional) async {
    await _dio.post('/api/admin/fee-masters/fee-types', data: {
      'name': name,
      'description': description,
      'isOptional': isOptional,
    });
  }

  Future<void> deleteFeeType(String id) async {
    await _dio.delete('/api/admin/fee-masters/fee-types/$id');
  }

  // ── Fee Structures ─────────────────────────────────────────────────────────

  Future<List<FeeStructure>> fetchFeeStructures() async {
    final res = await _dio.get('/api/admin/fee-masters/fee-structures');
    return _extractList(res.data)
        .map((e) => FeeStructure.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createFeeStructure(Map<String, dynamic> data) async {
    await _dio.post('/api/admin/fee-masters/fee-structures', data: data);
  }

  // ── Concessions ────────────────────────────────────────────────────────────

  Future<List<ConcessionType>> fetchConcessions() async {
    final res = await _dio.get('/api/admin/fee-masters/concession-types');
    return _extractList(res.data)
        .map((e) => ConcessionType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createConcession(Map<String, dynamic> data) async {
    await _dio.post('/api/admin/fee-masters/concession-types', data: data);
  }

  Future<void> deleteConcession(String id) async {
    await _dio.delete('/api/admin/fee-masters/concession-types/$id');
  }

  // ── Late Fee Config ────────────────────────────────────────────────────────

  Future<LateFeeConfig> fetchLateFeeConfig() async {
    final res = await _dio.get('/api/admin/fee-masters/late-fee');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final item = data['data'] ?? data;
      return LateFeeConfig.fromJson(item as Map<String, dynamic>);
    }
    return const LateFeeConfig(graceDays: 0, finePerDay: 0, maxFine: 0);
  }

  Future<void> updateLateFeeConfig(Map<String, dynamic> data) async {
    await _dio.patch('/api/admin/fee-masters/late-fee', data: data);
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'feeTypes', 'structures', 'concessions']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final feeMasterRepositoryProvider = Provider<FeeMasterRepository>((ref) {
  return FeeMasterRepository(ref.watch(dioClientProvider));
});
