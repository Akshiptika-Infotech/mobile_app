import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/notification_repository.dart';
import 'package:mobile_app/features/admin/domain/notification_model.dart';

final notificationLogProvider =
    FutureProvider.autoDispose<List<SentNotification>>((ref) async {
  return ref.watch(notificationRepositoryProvider).fetchLog();
});
