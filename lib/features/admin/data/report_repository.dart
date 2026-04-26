import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(dioClientProvider));
});

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;

  /// Cached active-year id so we don't refetch on every chip switch.
  String? _activeYearId;

  /// Reports that require an `academicYearId` query parameter.
  static const _requiresYear = {'defaulters', 'transport', 'concessions'};

  Future<String?> _resolveActiveYear() async {
    if (_activeYearId != null) return _activeYearId;
    try {
      final res = await _dio.get('/api/admin/academic-years');
      final list = res.data is List
          ? res.data as List
          : (res.data is Map<String, dynamic>
              ? (res.data['data'] ?? res.data['years'] ?? res.data['academicYears'] ?? const [])
              : const []);
      Map<String, dynamic>? active;
      for (final raw in list as Iterable) {
        final m = raw as Map<String, dynamic>;
        if (m['isActive'] == true || m['active'] == true) {
          active = m; break;
        }
      }
      active ??= (list.isNotEmpty ? list.first as Map<String, dynamic> : null);
      _activeYearId = active?['id']?.toString();
    } catch (_) {/* leave null */}
    return _activeYearId;
  }

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
    String? academicYearId;
    if (_requiresYear.contains(type)) {
      academicYearId = await _resolveActiveYear();
    }

    // Backend exposes one route per report type at /api/admin/reports/{type}.
    final response = await _dio.get(
      '/api/admin/reports/$type',
      queryParameters: {
        if (academicYearId != null) 'academicYearId': academicYearId,
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
      // Each backend report wraps its list under a different key:
      //   collection → collections, defaulters → defaulters,
      //   receipts → receipts, students → students,
      //   transport → assignments, concessions → assignments,
      //   staff-attendance → records.
      // Try the well-known keys, then fall back to the first list-valued
      // entry in the payload.
      const known = [
        'data', 'rows', 'results', 'report', 'records',
        'collections', 'defaulters', 'receipts',
        'students', 'staff', 'assignments', 'attendance',
        'items',
      ];
      for (final key in known) {
        if (data[key] is List) return data[key] as List;
      }
      for (final v in data.values) {
        if (v is List) return v;
      }
    }
    return [];
  }
}
