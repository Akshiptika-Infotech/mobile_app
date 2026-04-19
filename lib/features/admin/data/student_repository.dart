import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/student_model.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(dioClientProvider));
});

class StudentRepository {
  StudentRepository(this._dio);

  final Dio _dio;

  Future<StudentsPage> fetchStudents({
    String search = '',
    String status = 'active',
    int page = 1,
    int limit = 25,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search.isNotEmpty) 'search': search,
      // Only send status for the transferred tab; omit for active
      // so the API returns its natural default (all active students).
      if (status != 'active') 'status': status,
    };
    final response = await _dio.get(
      '/api/admin/students',
      queryParameters: params,
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StudentsPage.fromJson(data);
    }
    if (data is List) {
      return StudentsPage(
        students: data
            .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: data.length,
        page: page,
        hasMore: data.length >= limit,
      );
    }
    throw Exception('Unexpected students response format');
  }

  Future<StudentModel> fetchStudent(String id) async {
    final response = await _dio.get('/api/admin/students/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StudentModel.fromJson(data);
    }
    throw Exception('Unexpected student response format');
  }

  Future<StudentModel> createStudent(Map<String, dynamic> payload) async {
    final response = await _dio.post('/api/admin/students', data: payload);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StudentModel.fromJson(data);
    }
    throw Exception('Unexpected create student response format');
  }

  Future<StudentModel> updateStudent(
      String id, Map<String, dynamic> payload) async {
    final response =
        await _dio.patch('/api/admin/students/$id', data: payload);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StudentModel.fromJson(data);
    }
    throw Exception('Unexpected update student response format');
  }
}
