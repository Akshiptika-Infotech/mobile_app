import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/certificate_model.dart';

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepository(ref.watch(dioClientProvider));
});

class CertificateRepository {
  CertificateRepository(this._dio);

  final Dio _dio;

  Future<List<CertificateModel>> fetchCertificates() async {
    final response = await _dio.get('/api/admin/certificates');
    final list = _extractList(response.data);
    return list
        .map((e) => CertificateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Issues a certificate via `POST /api/admin/certificates`. The backend
  /// schema requires `{type, recipientType, recipientId, data, templateId?}`.
  Future<CertificateModel> issueCertificate({
    required String studentId,
    required String type,
    required String date,
    String recipientType = 'STUDENT',
    Map<String, dynamic>? extraData,
    String? templateId,
  }) async {
    final response = await _dio.post(
      '/api/admin/certificates',
      data: {
        'type': type,
        'recipientType': recipientType,
        'recipientId': studentId,
        'data': {'date': date, ...?extraData},
        if (templateId != null) 'templateId': templateId,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final item = data['data'] ?? data['certificate'] ?? data;
      return CertificateModel.fromJson(item as Map<String, dynamic>);
    }
    throw Exception('Unexpected certificate issue response format');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'certificates', 'results']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
