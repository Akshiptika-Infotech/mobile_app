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
  /// Hits `/api/public/branding` which returns `{name, initials, logoPath}`.
  /// Returns an empty SchoolInfo on failure so the login screen can
  /// gracefully fall back to the flavor icon.
  Future<SchoolInfo> fetchPublicInfo() async {
    try {
      final response = await _dio.get(
        '/api/public/branding',
        options: Options(
          validateStatus: (status) => status == 200,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final name = (data['name'] ?? '').toString().trim();
        final logo = (data['logoPath'] ?? data['logoUrl'] ?? '').toString().trim();
        return SchoolInfo(
          name: name,
          logoUrl: logo.isNotEmpty ? logo : null,
        );
      }
    } catch (_) {/* fall through */}
    return const SchoolInfo(name: '');
  }
}

final schoolInfoRepositoryProvider = Provider<SchoolInfoRepository>((ref) {
  return SchoolInfoRepository(ref.watch(dioClientProvider));
});

final schoolInfoProvider = FutureProvider<SchoolInfo>((ref) {
  return ref.watch(schoolInfoRepositoryProvider).fetchPublicInfo();
});
