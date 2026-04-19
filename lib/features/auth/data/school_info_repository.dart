import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';

class SchoolInfo {
  const SchoolInfo({required this.name, this.logoUrl});
  final String name;
  final String? logoUrl;
}

class SchoolInfoRepository {
  SchoolInfoRepository(this._dio);
  final Dio _dio;

  /// Fetches public school info (name + logo) without requiring auth.
  /// Tries /api/public/school first, then /api/admin/settings.
  /// Returns an empty SchoolInfo on failure so the login screen
  /// can gracefully fall back to the flavor icon.
  Future<SchoolInfo> fetchPublicInfo() async {
    for (final path in ['/api/public/school', '/api/admin/settings']) {
      try {
        final response = await _dio.get(
          path,
          options: Options(
            validateStatus: (status) => status == 200,
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final name =
              (data['schoolName'] ?? data['name'] ?? '').toString().trim();
          final logoUrl =
              (data['logoUrl'] ?? data['logo'] ?? '').toString().trim();
          return SchoolInfo(
            name: name,
            logoUrl: logoUrl.isNotEmpty ? logoUrl : null,
          );
        }
      } catch (_) {
        // try next endpoint
      }
    }
    return const SchoolInfo(name: '');
  }
}

final schoolInfoRepositoryProvider = Provider<SchoolInfoRepository>((ref) {
  return SchoolInfoRepository(ref.watch(dioClientProvider));
});

final schoolInfoProvider = FutureProvider<SchoolInfo>((ref) {
  return ref.watch(schoolInfoRepositoryProvider).fetchPublicInfo();
});
