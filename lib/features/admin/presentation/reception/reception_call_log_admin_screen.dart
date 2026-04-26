import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';

final _receptionCallLogProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/reception/call-log');
});

class ReceptionCallLogAdminScreen extends ConsumerWidget {
  const ReceptionCallLogAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_receptionCallLogProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Call Log'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_receptionCallLogProvider),
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
          onRetry: () => ref.invalidate(_receptionCallLogProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No call logs',
              icon: Icons.call_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final c = items[i];
              final caller = (c['callerName'] ?? c['name'] ?? '').toString();
              final purpose = (c['purpose'] ?? '').toString();
              final action = (c['actionTaken'] ?? c['action'] ?? '').toString();
              final handledBy = (c['handledBy'] ?? '').toString();
              final timestamp = (c['timestamp'] ?? c['time'] ?? c['createdAt'] ?? '').toString();
              final parsedTime = DateTime.tryParse(timestamp);
              final displayTime = parsedTime != null
                  ? DateFormat('dd MMM, hh:mm a').format(parsedTime.toLocal())
                  : timestamp;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.call_outlined, color: cs.onPrimaryContainer, size: 20),
                  ),
                  title: Text(caller, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (purpose.isNotEmpty)
                        Text('Purpose: $purpose',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      if (action.isNotEmpty)
                        Text('Action: $action',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      if (handledBy.isNotEmpty)
                        Text('Handled by: $handledBy',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      if (displayTime.isNotEmpty)
                        Text(displayTime,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
