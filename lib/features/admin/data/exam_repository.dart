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

  Future<List<StudentMark>> fetchStudentMarks(String subjectId) async {
    final response = await _dio.get(
      '/api/admin/exams/marks',
      queryParameters: {'subjectId': subjectId},
    );
    final data = response.data;
    final list = _extractList(data);
    return list
        .map((e) => StudentMark.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitMarks(
    String subjectId,
    List<Map<String, dynamic>> marks,
  ) async {
    await _dio.post(
      '/api/admin/exams/marks',
      data: {'subjectId': subjectId, 'marks': marks},
    );
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
