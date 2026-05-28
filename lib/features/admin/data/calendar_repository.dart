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

  /// Creates a calendar event. Scope rules (match backend
  /// `/api/admin/calendar` POST):
  ///   - `classId == null` → school-wide event.
  ///   - `classId` set, `sectionId == null` → class-wide.
  ///   - `classId` set, `sectionId` set → section-specific.
  /// The backend ignores `sectionId` when `classId` is null.
  Future<void> createEvent({
    required String title,
    required String description,
    required String eventType,
    required String startDate,
    required String endDate,
    String? classId,
    String? sectionId,
    String? color,
  }) async {
    await _dio.post('/api/admin/calendar', data: {
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'eventType': eventType.toUpperCase(),
      'startDate': '${startDate}T00:00:00.000Z',
      'endDate': '${endDate}T23:59:59.000Z',
      if (classId != null && classId.isNotEmpty) 'classId': classId,
      if (classId != null &&
          classId.isNotEmpty &&
          sectionId != null &&
          sectionId.isNotEmpty)
        'sectionId': sectionId,
      if (color != null && color.isNotEmpty) 'color': color,
    });
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete('/api/admin/calendar/$id');
  }
}
