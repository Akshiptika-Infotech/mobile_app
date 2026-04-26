import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/core/utils/response_utils.dart';
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
    final monthParam =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final response = await _dio.get(
      '/api/admin/calendar',
      queryParameters: {'month': monthParam},
    );
    return extractList(response.data, keys: const ['data', 'events', 'calendar'])
        .map(CalendarEvent.fromJson)
        .toList();
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required String eventType,
    required String date,
    String? targetClass,
  }) async {
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
}
