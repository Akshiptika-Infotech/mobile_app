import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';

final _receptionLateArrivalsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/reception/late-arrivals');
});

class ReceptionLateArrivalsAdminScreen extends ConsumerWidget {
  const ReceptionLateArrivalsAdminScreen({super.key});

  Future<void> _notifyParent(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref
          .read(adminViewsRepositoryProvider)
          .patch('/api/reception/late-arrivals/$id/notify', {});
      ref.invalidate(_receptionLateArrivalsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Parent notified')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_receptionLateArrivalsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Late Arrivals'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_receptionLateArrivalsProvider),
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
          onRetry: () => ref.invalidate(_receptionLateArrivalsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No late arrivals',
              icon: Icons.timer_off_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final l = items[i];
              final id = (l['id'] ?? '').toString();
              final name = (l['studentName'] ?? l['name'] ?? '').toString();
              final cls = (l['class'] ?? '').toString();
              final section = (l['section'] ?? '').toString();
              final reason = (l['reason'] ?? '').toString();
              final notified = l['notifyParent'] == true;

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
                        backgroundColor: cs.errorContainer,
                        child: Icon(Icons.timer_off_outlined,
                            color: cs.onErrorContainer, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (cls.isNotEmpty)
                              Text(
                                section.isNotEmpty ? 'Class $cls-$section' : 'Class $cls',
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            if (reason.isNotEmpty)
                              Text(
                                'Reason: $reason',
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                      if (notified)
                        Chip(
                          label: Text('Notified',
                              style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
                          backgroundColor: cs.primaryContainer,
                          padding: EdgeInsets.zero,
                        )
                      else if (id.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _notifyParent(context, ref, id),
                          icon: const Icon(Icons.notifications_outlined, size: 16),
                          label: const Text('Notify', style: TextStyle(fontSize: 12)),
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
