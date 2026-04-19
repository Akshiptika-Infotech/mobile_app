import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/features/parent/domain/parent_model.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';

class ParentRepository {
  const ParentRepository(this._dio);

  final Dio _dio;

  Future<List<AcademicYear>> fetchAcademicYears() async {
    final r = await _dio.get('/api/admin/academic-years');
    final data = r.data;
    final list = data is List ? data : <dynamic>[];
    return list
        .map((e) => AcademicYear.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChildSummary>> fetchChildren() async {
    final r = await _dio.get('/api/parent/children');
    final data = r.data as Map<String, dynamic>;
    final list = (data['children'] ?? <dynamic>[]) as List;
    return list
        .map((e) => ChildSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FeeMatrixData> fetchChildMatrix(
      String studentId, String academicYearId) async {
    final r = await _dio.get(
      '/api/parent/children/$studentId/matrix',
      queryParameters: {'academicYearId': academicYearId},
    );
    return FeeMatrixData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ParentReceipt>> fetchReceipts({
    String? studentId,
    int page = 1,
  }) async {
    final r = await _dio.get(
      '/api/parent/receipts',
      queryParameters: {
        'page': page,
        if (studentId != null) 'studentId': studentId,
      },
    );
    final data = r.data as Map<String, dynamic>;
    final list = (data['collections'] ?? <dynamic>[]) as List;
    return list
        .map((e) => ParentReceipt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CalendarEvent>> fetchCalendarEvents({
    required String studentId,
    required int month,
    required int year,
  }) async {
    final monthParam =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final r = await _dio.get(
      '/api/parent/calendar',
      queryParameters: {
        'studentId': studentId,
        'month': monthParam,
      },
    );
    final data = r.data;
    final list = _extractList(data);
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimetableEntry>> fetchTimetable(String studentId) async {
    final r = await _dio.get(
      '/api/parent/timetable',
      queryParameters: {'studentId': studentId},
    );
    final data = r.data as Map<String, dynamic>;
    final list = (data['entries'] ?? <dynamic>[]) as List;
    return list
        .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();
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

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'events', 'calendar']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(ref.watch(dioClientProvider));
});
