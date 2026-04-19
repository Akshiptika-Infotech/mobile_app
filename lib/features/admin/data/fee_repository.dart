import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/fee_model.dart';

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository(ref.watch(dioClientProvider));
});

class FeeRepository {
  FeeRepository(this._dio);

  final Dio _dio;

  Future<List<FeeSearchResult>> searchStudents(String query) async {
    final response = await _dio.get(
      '/api/admin/fee-collection',
      queryParameters: {'search': query},
    );
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      list = (data['collections'] ?? data['students'] ?? data['data'] ?? <dynamic>[]) as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .map((e) => FeeSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeeStudentSummary> fetchFeeMatrix(String studentId) async {
    final response = await _dio.get(
      '/api/admin/fee-collection',
      queryParameters: {'studentId': studentId},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return FeeStudentSummary.fromJson(data);
    }
    throw Exception('Unexpected fee matrix response format');
  }

  Future<FeeReceipt> submitFeeCollection({
    required String studentId,
    required List<Map<String, dynamic>> selectedMonths,
    required double amount,
    required String paymentMode,
    required String receiptNumber,
    required String date,
  }) async {
    final response = await _dio.post(
      '/api/admin/fee-collection',
      data: {
        'studentId': studentId,
        'months': selectedMonths,
        'amount': amount,
        'paymentMode': paymentMode,
        'receiptNumber': receiptNumber,
        'date': date,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return FeeReceipt.fromJson(data);
    }
    throw Exception('Unexpected fee collection response format');
  }

  Future<List<FeeHistoryItem>> fetchHistory({
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dio.get(
      '/api/admin/fee-collection/history',
      queryParameters: {
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
      },
    );
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      list = (data['history'] ?? data['data'] ?? <dynamic>[]) as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .map((e) => FeeHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeCollection(String id, String reason) async {
    await _dio.post(
      '/api/admin/fee-collection/$id/revoke',
      data: {'reason': reason},
    );
  }
}
