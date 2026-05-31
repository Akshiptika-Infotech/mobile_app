import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(ref.watch(dioClientProvider));
});

/// Thrown when the backend rejects a marks save because the entry window has
/// closed (HTTP 403). Callers should flip the screen to its read-only state
/// rather than treat it as a generic failure.
class MarksLockedException implements Exception {
  MarksLockedException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Result of loading marks for a subject. Carries the roster plus the
/// load-level `locked` / `marksEntryDeadline` flags returned by
/// `/api/admin/exams/marks` (which may close the window even when the
/// `/api/teacher/exams` row did not flag it).
class StudentMarksResult {
  const StudentMarksResult({
    required this.students,
    this.locked = false,
    this.marksEntryDeadline,
  });

  final List<StudentMark> students;
  final bool locked;
  final DateTime? marksEntryDeadline;
}

class ExamRepository {
  ExamRepository(this._dio);

  final Dio _dio;

  Future<List<ExamSubject>> fetchExamSubjects() async {
    final response = await _dio.get('/api/teacher/exams');
    final data = response.data;
    final list = _extractList(data);
    return list
        .map((e) => ExamSubject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentMarksResult> fetchStudentMarks(ExamSubject subject) async {
    // The backend `/api/admin/exams/marks` returns 400 on any missing
    // required id — fail fast with a clear message instead of letting
    // the user see a generic DioException.
    final missing = <String>[];
    if (subject.examTypeId.isEmpty) missing.add('examTypeId');
    if (subject.subjectId.isEmpty) missing.add('subjectId');
    if (subject.classId.isEmpty) missing.add('classId');
    if (missing.isNotEmpty) {
      throw Exception(
        'This subject is missing ${missing.join(", ")} from '
        '/api/teacher/exams. Ask the backend to include the field(s).',
      );
    }

    try {
      final response = await _dio.get(
        '/api/admin/exams/marks',
        queryParameters: {
          'examTypeId': subject.examTypeId,
          'subjectId': subject.subjectId,
          'classId': subject.classId,
          // sectionId is now always the teacher's section; pass it through
          // unconditionally so the backend scopes the roster correctly.
          if (subject.sectionId != null && subject.sectionId!.isNotEmpty)
            'sectionId': subject.sectionId,
        },
      );
      final students = _parseMarksResponse(response.data, subject.subjectId);
      final data = response.data;
      bool locked = false;
      DateTime? deadline;
      if (data is Map) {
        locked = data['locked'] == true;
        final raw = data['marksEntryDeadline'] ?? data['marks_entry_deadline'];
        if (raw != null && raw.toString().isNotEmpty) {
          deadline = DateTime.tryParse(raw.toString())?.toLocal();
        }
      }
      return StudentMarksResult(
        students: students,
        locked: locked,
        marksEntryDeadline: deadline,
      );
    } on DioException catch (e) {
      // Show the server's actual error string instead of the generic
      // status-code wall of text.
      final body = e.response?.data;
      String? msg;
      if (body is Map && body['error'] is String) {
        msg = body['error'] as String;
      } else if (body is String && body.isNotEmpty) {
        msg = body;
      }
      throw Exception(msg ?? 'Failed to load students (HTTP ${e.response?.statusCode}).');
    }
  }

  Future<void> submitMarks(
    ExamSubject subject,
    List<Map<String, dynamic>> marks, {
    String status = 'SUBMITTED',
  }) async {
    final rows = marks
        .where((m) => m['marksObtained'] != null || m['grade'] != null)
        .map((m) => {
              'studentId': m['studentId'],
              'subjectId': subject.subjectId,
              if (m['marksObtained'] != null)
                'marksObtained': m['marksObtained'],
              if (m['grade'] != null) 'grade': m['grade'],
              'status': status,
            })
        .toList();
    try {
      await _dio.post(
        '/api/admin/exams/marks',
        data: {'examTypeId': subject.examTypeId, 'rows': rows},
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      String? msg;
      if (body is Map && body['error'] is String) {
        msg = body['error'] as String;
      } else if (body is String && body.isNotEmpty) {
        msg = body;
      }
      // 403 → the marks-entry window is closed; surface a typed error so the
      // notifier can switch the screen to read-only instead of showing a
      // generic save failure.
      if (e.response?.statusCode == 403) {
        throw MarksLockedException(msg ??
            'Marks entry for this exam is closed. '
                'Contact an administrator to make changes.');
      }
      throw Exception(
          msg ?? 'Failed to save marks (HTTP ${e.response?.statusCode}).');
    }
  }

  /// Parses `{ students, marks }` where `marks` is keyed by `${studentId}_${subjectId}`.
  /// Falls back to a flat list if the backend ever returns that shape.
  /// Result is sorted alphabetically by student name (case-insensitive).
  static List<StudentMark> _parseMarksResponse(dynamic data, String subjectId) {
    List<StudentMark> result;
    if (data is Map<String, dynamic> &&
        data['students'] is List &&
        data['marks'] is Map) {
      final students = data['students'] as List;
      final marksMap = data['marks'] as Map;
      result = students.map((raw) {
        final s = raw as Map<String, dynamic>;
        final id = (s['id'] ?? '').toString();
        final first = (s['firstName'] ?? '').toString();
        final last = (s['lastName'] ?? '').toString();
        final name = '$first $last'.trim();
        final mark = marksMap['${id}_$subjectId'];
        int? marksObtained;
        String? grade;
        if (mark is Map) {
          final m = mark['marksObtained'];
          if (m is num) {
            marksObtained = m.toInt();
          } else if (m != null) {
            marksObtained = int.tryParse(m.toString());
          }
          grade = mark['grade']?.toString();
        }
        return StudentMark(
          studentId: id,
          studentName: name.isNotEmpty ? name : (s['name'] ?? '').toString(),
          admissionNumber: (s['admissionNumber'] ?? '').toString(),
          photoUrl: (s['photoUrl'] ??
                  s['photo_url'] ??
                  s['photoPath'] ??
                  s['photo_path'])
              ?.toString(),
          marksObtained: marksObtained,
          grade: grade,
        );
      }).toList();
    } else {
      final list = _extractList(data);
      result = list
          .map((e) => StudentMark.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    result.sort((a, b) =>
        a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase()));
    return result;
  }

  Future<List<ReportCard>> fetchReportCards(String classId) async {
    final response = await _dio.get(
      '/api/admin/exams/report-cards',
      queryParameters: {'classId': classId},
    );
    final data = response.data;
    final list = _extractList(data);
    return list
        .map((e) => ReportCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in [
        'data',
        'subjects',
        'students',
        'marks',
        'reportCards',
        'report_cards'
      ]) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
