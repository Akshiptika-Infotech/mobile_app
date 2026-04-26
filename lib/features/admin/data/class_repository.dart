import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';

class ClassRepository {
  ClassRepository(this._dio);
  final Dio _dio;

  Future<List<SchoolClass>> fetchClasses() async {
    final res = await _dio.get('/api/admin/classes');
    final list = _extractList(res.data);
    return list
        .map((e) => SchoolClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createClass(
    String name,
    String academicYear,
    List<String> sections,
  ) async {
    await _dio.post('/api/admin/classes', data: {
      'name': name,
      'academicYear': academicYear,
      'sections': sections,
    });
  }

  Future<List<AcademicYear>> fetchAcademicYears() async {
    final res = await _dio.get('/api/admin/academic-years');
    final list = _extractList(res.data);
    return list
        .map((e) => AcademicYear.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAcademicYear(
    String name,
    String startDate,
    String endDate,
  ) async {
    await _dio.post('/api/admin/academic-years', data: {
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  Future<void> deleteClass(String id) async {
    await _dio.delete('/api/admin/classes/$id');
  }

  Future<void> setActiveYear(String id) async {
    await _dio.patch('/api/admin/academic-years/$id');
  }

  /// Returns every section in the school, flattened from the classes
  /// endpoint (the backend has no dedicated `/api/admin/sections` route —
  /// each class includes its sections inline).
  Future<List<Section>> fetchSections() async {
    final res = await _dio.get('/api/admin/classes');
    final classes = _extractList(res.data);
    final sections = <Section>[];
    for (final c in classes) {
      final cls = c as Map<String, dynamic>;
      final raw = cls['sections'];
      if (raw is List) {
        for (final s in raw) {
          sections.add(Section.fromJson(s as Map<String, dynamic>));
        }
      }
    }
    return sections;
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'classes', 'years', 'academicYears']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository(ref.watch(dioClientProvider));
});
