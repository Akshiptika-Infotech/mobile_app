import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';

class StudentPortalRepository {
  const StudentPortalRepository(this._dio);

  final Dio _dio;

  Future<List<AcademicYear>> fetchAcademicYears() async {
    final r = await _dio.get('/api/admin/academic-years');
    final data = r.data;
    final list = data is List ? data : <dynamic>[];
    return list
        .map((e) => AcademicYear.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeeMatrixData> fetchFeeMatrix(String academicYearId) async {
    final r = await _dio.get(
      '/api/student/matrix',
      queryParameters: {'academicYearId': academicYearId},
    );
    return FeeMatrixData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<StudentReceipt>> fetchReceipts({int page = 1}) async {
    final r = await _dio.get(
      '/api/student/receipts',
      queryParameters: {'page': page},
    );
    final data = r.data as Map<String, dynamic>;
    final list = (data['collections'] ?? <dynamic>[]) as List;
    return list
        .map((e) => StudentReceipt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentTransportInfo> fetchTransport(String academicYearId) async {
    final r = await _dio.get(
      '/api/student/transport',
      queryParameters: {'academicYearId': academicYearId},
    );
    return StudentTransportInfo.fromJson(r.data as Map<String, dynamic>);
  }

  Future<CreateOrderResponse> createPaymentOrder({
    required String studentId,
    required String academicYearId,
    required List<SelectedPaymentItem> items,
  }) async {
    final r = await _dio.post(
      '/api/payment/create-order',
      data: {
        'studentId': studentId,
        'academicYearId': academicYearId,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );
    return CreateOrderResponse.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> verifyPayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _dio.post(
      '/api/payment/verify',
      data: {
        'paymentId': paymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
  }
}

final studentPortalRepositoryProvider =
    Provider<StudentPortalRepository>((ref) {
  return StudentPortalRepository(ref.watch(dioClientProvider));
});
