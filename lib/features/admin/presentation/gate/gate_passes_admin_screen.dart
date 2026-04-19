import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';

final _gatePassesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/admin/gate-passes');
});

class GatePassesAdminScreen extends ConsumerWidget {
  const GatePassesAdminScreen({super.key});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String id, String status) async {
    try {
      await ref.read(adminViewsRepositoryProvider).patch(
          '/api/admin/gate-passes/$id', {'status': status});
      ref.invalidate(_gatePassesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_gatePassesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Gate Passes'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_gatePassesProvider),
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
          onRetry: () => ref.invalidate(_gatePassesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No gate pass requests',
              icon: Icons.badge_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final p = items[i];
              final id = (p['id'] ?? '').toString();
              final status = (p['status'] ?? 'pending').toString();
              final isPending = status == 'pending';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.secondaryContainer,
                        child: Icon(Icons.badge_outlined, color: cs.onSecondaryContainer, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (p['studentName'] ?? p['name'] ?? 'Student').toString(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Purpose: ${(p['purpose'] ?? '').toString()}',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                            if ((p['requestedAt'] ?? '').toString().isNotEmpty)
                              Text(
                                (p['requestedAt'] ?? '').toString(),
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPending)
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _updateStatus(context, ref, id, 'approved'),
                              icon: Icon(Icons.check_circle_outline, color: cs.primary),
                              tooltip: 'Approve',
                            ),
                            IconButton(
                              onPressed: () => _updateStatus(context, ref, id, 'rejected'),
                              icon: Icon(Icons.cancel_outlined, color: cs.error),
                              tooltip: 'Reject',
                            ),
                          ],
                        )
                      else
                        Chip(
                          label: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: status == 'approved' ? cs.onPrimaryContainer : cs.onErrorContainer,
                            ),
                          ),
                          backgroundColor:
                              status == 'approved' ? cs.primaryContainer : cs.errorContainer,
                          padding: EdgeInsets.zero,
                        ),
                    ],
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
