import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._dio);
  final Dio _dio;

  Future<void> sendNotification(
    String title,
    String message,
    String targetRole,
    String? targetClass,
  ) async {
    await _dio.post('/api/admin/notifications/send', data: {
      'title': title,
      'message': message,
      'targetRole': targetRole,
      if (targetClass != null && targetClass.isNotEmpty)
        'targetClass': targetClass,
    });
  }

  Future<List<SentNotification>> fetchLog() async {
    final res = await _dio.get('/api/admin/notifications/log');
    final data = res.data;
    final list = _extractList(data);
    return list
        .map((e) => SentNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['data', 'notifications', 'log']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioClientProvider));
});
