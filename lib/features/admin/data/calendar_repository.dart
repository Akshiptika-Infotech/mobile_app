import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(dioClientProvider));
});

class CalendarRepository {
  CalendarRepository(this._dio);

  final Dio _dio;

  Future<List<CalendarEvent>> fetchEvents({
    required int month,
    required int year,
  }) async {
    // API expects month as "YYYY-MM" format
    final monthParam =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      '/api/admin/calendar',
      queryParameters: {'month': monthParam},
    );
    final data = response.data;
    final list = _extractList(data);
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required String eventType,
    required String date,     // "yyyy-MM-dd"
    String? targetClass,
  }) async {
    // API requires startDate, endDate, eventType (not type/date)
    // Default endDate = same day (all-day event)
    await _dio.post('/api/admin/calendar', data: {
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'eventType': eventType.toUpperCase(),
      'startDate': '${date}T00:00:00.000Z',
      'endDate': '${date}T23:59:59.000Z',
      if (targetClass != null && targetClass.isNotEmpty) 'classId': targetClass,
    });
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete('/api/admin/calendar/$id');
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'events', 'calendar']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
