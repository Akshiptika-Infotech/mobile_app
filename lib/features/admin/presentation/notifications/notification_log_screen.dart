import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/providers/notification_provider.dart';

class NotificationLogScreen extends ConsumerWidget {
  const NotificationLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(notificationLogProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Notification Log'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(notificationLogProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: data.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 8),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationLogProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_none,
              message: 'No notifications sent yet',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final sentAt = DateTime.tryParse(item.sentAt);
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ListTile(
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(
                        'Role: ${item.targetRole}${(item.targetClass ?? '').isNotEmpty ? '  Class: ${item.targetClass}' : ''}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                      Text(
                        sentAt == null ? item.sentAt : DateFormat('dd MMM yyyy, hh:mm a').format(sentAt.toLocal()),
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(item.deliveredCount.toString()),
                    avatar: const Icon(Icons.done_all, size: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

