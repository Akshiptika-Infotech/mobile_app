import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/teacher/domain/leave_request_model.dart';

final teacherLeaveRepositoryProvider = Provider<TeacherLeaveRepository>((ref) {
  return TeacherLeaveRepository(ref.watch(dioClientProvider));
});

/// Repository for the teacher's own leave requests.
///
/// Hits `/api/admin/attendance/leaves` — the backend auto-scopes the GET
/// response to the current user when the role is TEACHER, and the POST
/// always creates a request for the current user.
class TeacherLeaveRepository {
  TeacherLeaveRepository(this._dio);

  final Dio _dio;

  Future<List<LeaveRequestModel>> fetchMyLeaves({String? status}) async {
    final response = await _dio.get(
      '/api/admin/attendance/leaves',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final raw = response.data;
    final list = raw is List
        ? raw
        : (raw is Map<String, dynamic>
            ? (raw['data'] ?? raw['leaves'] ?? const <dynamic>[]) as List
            : const <dynamic>[]);
    return list
        .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LeaveRequestModel> submitLeave({
    required DateTime fromDate,
    required DateTime toDate,
    required String leaveType,
    required String reason,
  }) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final response = await _dio.post(
      '/api/admin/attendance/leaves',
      data: {
        'fromDate': fmt(fromDate),
        'toDate': fmt(toDate),
        'leaveType': leaveType,
        'reason': reason,
      },
    );
    return LeaveRequestModel.fromJson(response.data as Map<String, dynamic>);
  }
}
