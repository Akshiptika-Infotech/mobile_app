import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioClientProvider));
});

class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

  Future<MyClassAttendanceResponse> fetchMyClassForDate(String date) async {
    final response = await _dio.get(
      '/api/teacher/attendance',
      queryParameters: {'date': date},
    );
    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      return const MyClassAttendanceResponse(
        students: [],
        classId: null,
        sectionId: null,
        academicYearId: null,
        locked: false,
      );
    }

    // Server now echoes classId, sectionId, academicYearId directly in GET response
    final classId = data['classId']?.toString();
    final sectionId = data['sectionId']?.toString();
    final academicYearId = data['academicYearId']?.toString();
    final locked = data['locked'] == true;

    final list = _extractList(data);
    final students = list
        .map((e) => AttendanceStudent.fromJson(e as Map<String, dynamic>))
        .toList();

    return MyClassAttendanceResponse(
      students: students,
      classId: classId,
      academicYearId: academicYearId,
      sectionId: sectionId,
      locked: locked,
    );
  }

  Future<void> submitAttendance({
    required String date,
    required List<Map<String, dynamic>> records,
    String? classId,
    String? academicYearId,
    String? sectionId,
  }) async {
    final normalised = records
        .map((r) => {...r, 'status': (r['status'] as String).toUpperCase()})
        .toList();
    final body = <String, dynamic>{
      'date': date,
      'records': normalised,
      if (classId != null) 'classId': classId,
      if (academicYearId != null) 'academicYearId': academicYearId,
      if (sectionId != null) 'sectionId': sectionId,
    };
    await _dio.post('/api/teacher/attendance', data: body);
  }

  Future<MyAttendanceSummary> fetchMyAttendance() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();
    final response = await _dio.get(
      '/api/admin/attendance/staff/me',
      queryParameters: {'start': start, 'end': end},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MyAttendanceSummary.fromJson(data);
    }
    throw Exception('Unexpected attendance response format');
  }

  Future<List<AttendanceRecord>> fetchStudentAttendance({
    String? className,
    String? date,
  }) async {
    final response = await _dio.get(
      '/api/admin/attendance/students',
      queryParameters: {
        if (className != null && className.isNotEmpty) 'class': className,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    final list = _extractList(response.data);
    return list
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceRecord>> fetchStaffAttendance({String? date}) async {
    final response = await _dio.get(
      '/api/admin/attendance/staff',
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    final list = _extractList(response.data);
    return list
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchLeaveRequests() async {
    final response = await _dio.get('/api/admin/attendance/leaves');
    final list = _extractList(response.data);
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> updateLeaveStatus(String id, String status) async {
    await _dio.patch('/api/admin/attendance/leaves/$id', data: {'status': status});
  }

  Future<QrScanResult> submitQrScan({
    required String qrData,
    required String date,
    required String classId,
    required String academicYearId,
    String? sectionId,
  }) async {
    final r = await _dio.post('/api/teacher/attendance/qr-scan', data: {
      'qrData': qrData,
      'date': date,
      'classId': classId,
      'academicYearId': academicYearId,
      if (sectionId != null) 'sectionId': sectionId,
    });
    return QrScanResult.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<LiveAttendanceStudent>> fetchQrLiveList({
    required String date,
    required String classId,
    required String academicYearId,
    String? sectionId,
  }) async {
    final r = await _dio.get('/api/teacher/attendance/qr-scan', queryParameters: {
      'date': date,
      'classId': classId,
      'academicYearId': academicYearId,
      if (sectionId != null) 'sectionId': sectionId,
    });
    final data = r.data as Map<String, dynamic>;
    final list = (data['students'] ?? <dynamic>[]) as List;
    return list
        .map((e) => LiveAttendanceStudent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in [
        'data',
        'students',
        'attendance',
        'records'
      ]) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
