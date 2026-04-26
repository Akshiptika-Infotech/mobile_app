import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/core/utils/response_utils.dart';
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
    return extractList(res.data, keys: const ['data', 'notifications', 'log'])
        .map(SentNotification.fromJson)
        .toList();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioClientProvider));
});
