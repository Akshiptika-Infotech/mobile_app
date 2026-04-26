import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/reception/domain/reception_model.dart';

class ReceptionRepository {
  const ReceptionRepository(this._dio);
  final Dio _dio;

  /// No `/api/reception/dashboard` route exists on the backend — assemble
  /// the four counters from the underlying list endpoints in parallel.
  Future<ReceptionDashboard> fetchDashboard() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final results = await Future.wait([
      _dio.get('/api/reception/appointments', queryParameters: {'date': today}),
      _dio.get('/api/reception/gate-passes',  queryParameters: {'status': 'PENDING'}),
      _dio.get('/api/reception/call-log',     queryParameters: {'date': today}),
      _dio.get('/api/reception/late-arrivals', queryParameters: {'date': today}),
    ]);
    return ReceptionDashboard(
      todayAppointments: _count(results[0].data),
      pendingPasses:     _count(results[1].data),
      callsLogged:       _count(results[2].data),
      lateArrivals:      _count(results[3].data),
    );
  }

  static int _count(dynamic data) {
    if (data is List) return data.length;
    if (data is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'rows', 'results',
          'visitors', 'appointments', 'passes', 'calls', 'lateArrivals',
          'late_arrivals']) {
        if (data[key] is List) return (data[key] as List).length;
      }
      if (data['total'] is num) return (data['total'] as num).toInt();
      if (data['count'] is num) return (data['count'] as num).toInt();
    }
    return 0;
  }

  // ── Visitors ───────────────────────────────────────────────────────────────

  Future<List<ReceptionVisitor>> fetchVisitors() async {
    final res = await _dio.get('/api/reception/visitors', queryParameters: {'today': '1'});
    final data = res.data;
    final list = (data is List ? data : (data['visitors'] ?? data['data'] ?? <dynamic>[])) as List;
    return list.map((e) => ReceptionVisitor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> registerVisitor({
    required String fullName,
    required String phone,
    required String purposeOfVisit,
    String? email,
    String? personToMeet,
    String? vehicleNumber,
  }) async {
    await _dio.post('/api/reception/visitors', data: {
      'fullName': fullName,
      'phone': phone,
      'purposeOfVisit': purposeOfVisit,
      if (email != null && email.isNotEmpty) 'email': email,
      if (personToMeet != null && personToMeet.isNotEmpty) 'personToMeet': personToMeet,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty) 'vehicleNumber': vehicleNumber,
    });
  }

  // ── Gate passes ────────────────────────────────────────────────────────────

  Future<List<ReceptionGatePass>> fetchGatePasses() async {
    final res = await _dio.get('/api/reception/gate-passes');
    final data = res.data;
    final list = (data is List ? data : (data['passes'] ?? data['gatePasses'] ?? <dynamic>[])) as List;
    return list.map((e) => ReceptionGatePass.fromJson(e as Map<String, dynamic>)).toList();
  }

  @Deprecated('Use registerVisitor instead')
  Future<void> createVisitorWithPass({
    required String name,
    required String phone,
    required String purpose,
    required String hostName,
  }) => registerVisitor(
        fullName: name,
        phone: phone,
        purposeOfVisit: purpose,
        personToMeet: hostName,
      );

  // ── Call log ───────────────────────────────────────────────────────────────

  Future<List<CallLog>> fetchCallLog() async {
    final res = await _dio.get('/api/reception/call-log');
    final data = res.data;
    final list = (data is List ? data : (data['calls'] ?? data['logs'] ?? <dynamic>[])) as List;
    return list.map((e) => CallLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> logCall({
    required String callerName,
    required String phone,
    required String purpose,
    required String actionTaken,
  }) async {
    await _dio.post('/api/reception/call-log', data: {
      'callerName': callerName,
      'phone': phone,
      'purpose': purpose,
      'actionTaken': actionTaken,
    });
  }

  // ── Appointments ───────────────────────────────────────────────────────────

  Future<List<Appointment>> fetchAppointments() async {
    final res = await _dio.get('/api/reception/appointments');
    final data = res.data;
    final list = (data is List ? data : (data['appointments'] ?? <dynamic>[])) as List;
    return list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createAppointment({
    required String visitorName,
    required String phone,
    required String purpose,
    required String hostName,
    required String scheduledAt,
  }) async {
    await _dio.post('/api/reception/appointments', data: {
      'visitorName': visitorName,
      'phone': phone,
      'purpose': purpose,
      'hostName': hostName,
      'scheduledAt': scheduledAt,
    });
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _dio.patch('/api/reception/appointments/$id', data: {'status': status});
  }

  // ── Late arrivals ──────────────────────────────────────────────────────────

  Future<List<LateArrival>> fetchLateArrivals() async {
    final res = await _dio.get('/api/reception/late-arrivals');
    final data = res.data;
    final list = (data is List ? data : (data['arrivals'] ?? data['lateArrivals'] ?? <dynamic>[])) as List;
    return list.map((e) => LateArrival.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> registerLateArrival({
    required String studentName,
    required String className,
    required String section,
    required String reason,
    required bool notifyParent,
  }) async {
    await _dio.post('/api/reception/late-arrivals', data: {
      'studentName': studentName,
      'class': className,
      'section': section,
      'reason': reason,
      'notifyParent': notifyParent,
    });
  }
}

final receptionRepositoryProvider = Provider<ReceptionRepository>((ref) {
  return ReceptionRepository(ref.watch(dioClientProvider));
});
