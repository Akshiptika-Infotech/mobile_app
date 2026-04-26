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

  Future<List<TimetablePeriod>> fetchMyTimetable() async {
    final response = await _dio.get('/api/teacher/timetable');
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
}
