import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/core/utils/response_utils.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(dioClientProvider));
});

class TimetableRepository {
  TimetableRepository(this._dio);

  final Dio _dio;

  /// Fetches the teacher timetable for [scope]:
  /// - `mine` (default) → only the periods this teacher teaches, across all
  ///   classes/sections ("My Timetable").
  /// - `class` → the full grid of the teacher's assigned class/section,
  ///   including every teacher's periods ("My Class").
  Future<List<TimetablePeriod>> fetchTeacherTimetable({
    String scope = 'mine',
  }) async {
    final response = await _dio.get(
      '/api/teacher/timetable',
      queryParameters: {'scope': scope},
    );
    // Backend returns { entries: [...] }
    return extractList(response.data, keys: const ['entries', 'data', 'timetable', 'periods', 'schedule'])
        .map(TimetablePeriod.fromJson)
        .toList();
  }

  Future<List<TimetablePeriod>> fetchAdminTimetable() async {
    final response = await _dio.get('/api/admin/timetable');
    return extractList(response.data, keys: const ['entries', 'data', 'timetable', 'periods', 'schedule'])
        .map(TimetablePeriod.fromJson)
        .toList();
  }

  Future<void> createPeriod(Map<String, dynamic> data) async {
    await _dio.post('/api/admin/timetable', data: data);
  }

  Future<void> deletePeriod(String id) async {
    await _dio.delete('/api/admin/timetable/$id');
  }

  // ── Teacher self-service timetable ─────────────────────────────────────────

  /// Fetches the catalogue of subjects that can be placed on the timetable
  /// for a given class. These are distinct from exam subjects.
  Future<List<TimetableSubject>> fetchTimetableSubjects(String classId) async {
    final response = await _dio.get(
      '/api/admin/subjects',
      queryParameters: {'classId': classId},
    );
    return extractList(response.data, keys: const ['subjects', 'data', 'items'])
        .map((e) => TimetableSubject.fromJson(e))
        .toList();
  }

  Future<void> createTeacherPeriod({
    required String dayOfWeek,
    required int periodNumber,
    required String startTime,
    required String endTime,
    required String subjectId,
    String? sectionId,
    bool optionSlot = false,
  }) async {
    await _dio.post('/api/teacher/timetable', data: {
      'dayOfWeek': dayOfWeek,
      'periodNumber': periodNumber,
      'startTime': startTime,
      'endTime': endTime,
      'subjectId': subjectId,
      if (sectionId != null) 'sectionId': sectionId,
      if (optionSlot) 'optionSlot': true,
    });
  }

  Future<void> updateTeacherPeriod(
    String id, {
    String? startTime,
    String? endTime,
    String? subjectId,
  }) async {
    await _dio.put('/api/teacher/timetable/$id', data: {
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (subjectId != null) 'subjectId': subjectId,
    });
  }

  Future<void> deleteTeacherPeriod(String id) async {
    await _dio.delete('/api/teacher/timetable/$id');
  }
}

/// A subject from the timetable catalogue (`/api/admin/subjects`).
/// Distinct from [TeacherExamSubject].
class TimetableSubject {
  const TimetableSubject({
    required this.id,
    required this.name,
    this.code,
  });

  final String id;
  final String name;
  final String? code;

  factory TimetableSubject.fromJson(Map<String, dynamic> json) {
    return TimetableSubject(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: json['code']?.toString(),
    );
  }
}
