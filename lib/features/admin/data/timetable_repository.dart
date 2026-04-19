import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(dioClientProvider));
});

class TimetableRepository {
  TimetableRepository(this._dio);

  final Dio _dio;

  Future<List<TimetablePeriod>> fetchMyTimetable() async {
    final response = await _dio.get('/api/teacher/timetable');
    final data = response.data;
    final list = _extractList(data);
    return list
        .map((e) =>
            TimetablePeriod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimetablePeriod>> fetchAdminTimetable() async {
    final response = await _dio.get('/api/admin/timetable');
    final data = response.data;
    final list = _extractList(data);
    return list
        .map((e) => TimetablePeriod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPeriod(Map<String, dynamic> data) async {
    await _dio.post('/api/admin/timetable', data: data);
  }

  Future<void> deletePeriod(String id) async {
    await _dio.delete('/api/admin/timetable/$id');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'timetable', 'periods', 'schedule']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
