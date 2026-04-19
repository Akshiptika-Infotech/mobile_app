import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/attendance_repository.dart';
import 'package:mobile_app/features/admin/providers/attendance_provider.dart';

class LeaveRequestsScreen extends ConsumerWidget {
  const LeaveRequestsScreen({super.key});

  Future<void> _update(WidgetRef ref, String id, String status) async {
    await ref.read(attendanceRepositoryProvider).updateLeaveStatus(id, status);
    ref.invalidate(leaveRequestsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(leaveRequestsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: data.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 8),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(leaveRequestsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No leave requests',
              icon: Icons.event_busy_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final leave = items[i];
              final id = (leave['id'] ?? '').toString();
              final status = (leave['status'] ?? 'pending').toString();
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ListTile(
                  title: Text((leave['name'] ?? leave['staffName'] ?? leave['studentName'] ?? '').toString()),
                  subtitle: Text('Reason: ${(leave['reason'] ?? '').toString()}'),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _update(ref, id, 'approved'),
                              icon: Icon(Icons.check_circle_outline, color: cs.primary),
                            ),
                            IconButton(
                              onPressed: () => _update(ref, id, 'rejected'),
                              icon: Icon(Icons.cancel_outlined, color: cs.error),
                            ),
                          ],
                        )
                      : Chip(label: Text(status)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
