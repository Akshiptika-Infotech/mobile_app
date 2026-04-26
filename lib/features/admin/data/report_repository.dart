import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(dioClientProvider));
});

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;

  /// Fetches report data for [type].
  ///
  /// [type] must be one of:
  ///   collection | defaulters | receipts | students |
  ///   staff-attendance | transport | concessions
  ///
  /// Returns raw row maps because each report type has a different schema.
  Future<List<Map<String, dynamic>>> fetchReport({
    required String type,
    String? from,
    String? to,
  }) async {
    // Backend exposes one route per report type at /api/admin/reports/{type}.
    final response = await _dio.get(
      '/api/admin/reports/$type',
      queryParameters: {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    final data = response.data;
    final list = _extractList(data);
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'rows', 'results', 'report', 'records']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
