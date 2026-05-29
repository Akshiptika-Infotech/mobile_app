import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';

final teacherSubjectRepositoryProvider = Provider<TeacherSubjectRepository>(
  (ref) => TeacherSubjectRepository(ref.watch(dioClientProvider)),
);

class TeacherSubjectRepository {
  TeacherSubjectRepository(this._dio);

  final Dio _dio;

  Future<List<TeacherExamSubject>> fetchSubjects() async {
    final response = await _dio.get('/api/teacher/subjects');
    final data = response.data;
    final list = _extractList(data);
    return list
        .map((e) => TeacherExamSubject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherExamSubject> createSubject({
    required String name,
    required String code,
    required bool isGraded,
  }) async {
    final response = await _dio.post(
      '/api/teacher/subjects',
      data: {'name': name, 'code': code, 'isGraded': isGraded},
    );
    return TeacherExamSubject.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  Future<TeacherExamSubject> updateSubject(
    String id, {
    String? name,
    String? code,
    bool? isGraded,
  }) async {
    final response = await _dio.patch(
      '/api/teacher/subjects/$id',
      data: {
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (isGraded != null) 'isGraded': isGraded,
      },
    );
    return TeacherExamSubject.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  Future<void> deleteSubject(String id) async {
    await _dio.delete('/api/teacher/subjects/$id');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['subjects', 'data', 'items']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
