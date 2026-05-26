import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(ref.watch(dioClientProvider));
});

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

  Future<List<StudentMark>> fetchStudentMarks(ExamSubject subject) async {
    final response = await _dio.get(
      '/api/admin/exams/marks',
      queryParameters: {
        'examTypeId': subject.examTypeId,
        'subjectId': subject.subjectId,
        'classId': subject.classId,
        if (subject.sectionId != null) 'sectionId': subject.sectionId,
      },
    );
    return _parseMarksResponse(response.data, subject.subjectId);
  }

  Future<void> submitMarks(
    ExamSubject subject,
    List<Map<String, dynamic>> marks,
  ) async {
    final rows = marks
        .where((m) => m['marksObtained'] != null)
        .map((m) => {
              'studentId': m['studentId'],
              'subjectId': subject.subjectId,
              'marksObtained': m['marksObtained'],
              'status': 'SUBMITTED',
            })
        .toList();
    await _dio.post(
      '/api/admin/exams/marks',
      data: {'examTypeId': subject.examTypeId, 'rows': rows},
    );
  }

  /// Parses `{ students, marks }` where `marks` is keyed by `${studentId}_${subjectId}`.
  /// Falls back to a flat list if the backend ever returns that shape.
  static List<StudentMark> _parseMarksResponse(dynamic data, String subjectId) {
    if (data is Map<String, dynamic> &&
        data['students'] is List &&
        data['marks'] is Map) {
      final students = data['students'] as List;
      final marksMap = data['marks'] as Map;
      return students.map((raw) {
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
    }
    final list = _extractList(data);
    return list
        .map((e) => StudentMark.fromJson(e as Map<String, dynamic>))
        .toList();
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
