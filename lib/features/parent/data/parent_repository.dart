import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/features/parent/domain/child_model.dart';
import 'package:mobile_app/features/parent/domain/fee_matrix_model.dart';
import 'package:mobile_app/features/parent/domain/parent_profile_model.dart';
import 'package:mobile_app/features/parent/domain/parent_receipt_model.dart';
import 'package:mobile_app/features/parent/domain/parent_transport_model.dart';
import 'package:mobile_app/features/parent/domain/student_attendance_model.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(ref.watch(dioClientProvider));
});

class ParentRepository {
  ParentRepository(this._dio);

  final Dio _dio;

  // ── Profile + children ────────────────────────────────────────────────────

  Future<ParentProfile> fetchProfile() async {
    final res = await _dio.get('/api/parent/profile');
    return ParentProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ParentChild>> fetchChildren() async {
    final res = await _dio.get('/api/parent/children');
    final data = res.data;
    final list = (data is Map<String, dynamic> && data['children'] is List)
        ? data['children'] as List
        : (data is List ? data : const []);
    return list
        .map((e) => ParentChild.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fee matrix ────────────────────────────────────────────────────────────

  Future<FeeMatrix> fetchMatrix({
    required String studentId,
    required String academicYearId,
  }) async {
    final res = await _dio.get(
      '/api/parent/children/$studentId/matrix',
      queryParameters: {'academicYearId': academicYearId},
    );
    return FeeMatrix.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Receipts ──────────────────────────────────────────────────────────────

  Future<ParentReceiptsPage> fetchReceipts({
    String? studentId,
    String? academicYearId,
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/api/parent/receipts',
      queryParameters: {
        if (studentId != null) 'studentId': studentId,
        if (academicYearId != null) 'academicYearId': academicYearId,
        'page': page,
      },
    );
    return ParentReceiptsPage.fromJson(res.data as Map<String, dynamic>);
  }

  /// Fetches the PDF bytes for a receipt — opens via the shared
  /// `/api/receipts/:collectionId` endpoint.
  Future<List<int>> downloadReceiptPdf(String collectionId) async {
    final res = await _dio.get<List<int>>(
      '/api/receipts/$collectionId',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  // ── Calendar + Timetable ──────────────────────────────────────────────────

  Future<List<CalendarEvent>> fetchCalendar({
    required String studentId,
    String? monthYyyyMm,
  }) async {
    final res = await _dio.get(
      '/api/parent/calendar',
      queryParameters: {
        'studentId': studentId,
        if (monthYyyyMm != null) 'month': monthYyyyMm,
      },
    );
    final data = res.data;
    final list = (data is Map<String, dynamic> && data['events'] is List)
        ? data['events'] as List
        : const [];
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimetablePeriod>> fetchTimetable(String studentId) async {
    final res = await _dio.get(
      '/api/parent/timetable',
      queryParameters: {'studentId': studentId},
    );
    final data = res.data;
    final list = (data is Map<String, dynamic> && data['entries'] is List)
        ? data['entries'] as List
        : const [];
    return list
        .map((e) => TimetablePeriod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  /// `GET /api/parent/attendance?studentId=&month=YYYY-MM` — daily
  /// attendance for one month plus a small summary block.
  Future<({List<StudentAttendanceDay> days, StudentAttendanceSummary summary})>
      fetchAttendance({
    required String studentId,
    String? monthYyyyMm,
  }) async {
    final res = await _dio.get(
      '/api/parent/attendance',
      queryParameters: {
        'studentId': studentId,
        if (monthYyyyMm != null) 'month': monthYyyyMm,
      },
    );
    final data = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
    final dayList = (data['days'] as List? ?? const []);
    final summaryRaw =
        (data['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      days: dayList
          .map((e) =>
              StudentAttendanceDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: StudentAttendanceSummary.fromJson(summaryRaw),
    );
  }

  // ── Transport ─────────────────────────────────────────────────────────────

  /// `GET /api/parent/transport?studentId=` — child's route + assigned
  /// stoppage + activeTripId for live GPS subscription.
  Future<ParentTransport> fetchTransport(String studentId) async {
    final res = await _dio.get(
      '/api/parent/transport',
      queryParameters: {'studentId': studentId},
    );
    return ParentTransport.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Razorpay flow ─────────────────────────────────────────────────────────

  /// `POST /api/payment/create-order` — returns the order metadata the
  /// `razorpay_flutter` plugin needs to launch the checkout sheet.
  Future<RazorpayOrder> createPaymentOrder({
    required String studentId,
    required String academicYearId,
    required List<SelectedFeeLine> items,
  }) async {
    final res = await _dio.post('/api/payment/create-order', data: {
      'studentId': studentId,
      'academicYearId': academicYearId,
      'items': items.map((i) => i.toJson()).toList(),
    });
    return RazorpayOrder.fromJson(res.data as Map<String, dynamic>);
  }

  /// `POST /api/payment/verify` — confirms the Razorpay payment server-side
  /// so the FeeCollection rows can be written via webhook.
  Future<void> verifyPayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _dio.post('/api/payment/verify', data: {
      'paymentId': paymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    });
  }
}

class RazorpayOrder {
  const RazorpayOrder({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.paymentId,
    required this.key,
  });

  /// Razorpay order id (`order_xxx`).
  final String orderId;

  /// Amount in paise (already formatted by the backend).
  final int amountPaise;
  final String currency;

  /// Our `OnlinePayment.id` — passed back to verify.
  final String paymentId;

  /// Razorpay key id used to launch the checkout sheet.
  final String key;

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) => RazorpayOrder(
        orderId: (json['orderId'] ?? '').toString(),
        amountPaise: (json['amount'] is num)
            ? (json['amount'] as num).toInt()
            : int.tryParse(json['amount']?.toString() ?? '') ?? 0,
        currency: (json['currency'] ?? 'INR').toString(),
        paymentId: (json['paymentId'] ?? '').toString(),
        key: (json['key'] ?? '').toString(),
      );
}
