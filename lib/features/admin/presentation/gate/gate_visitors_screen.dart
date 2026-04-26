import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';

final _gateVisitorsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/admin/gate/visitors');
});

class GateVisitorsScreen extends ConsumerWidget {
  const GateVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_gateVisitorsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Gate Visitors'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_gateVisitorsProvider),
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
          onRetry: () => ref.invalidate(_gateVisitorsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No visitors found',
              icon: Icons.people_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final v = items[i];
              final name = (v['name'] ?? v['visitorName'] ?? 'Visitor').toString();
              final purpose = (v['purpose'] ?? '').toString();
              final inTime = (v['inTime'] ?? v['time'] ?? v['timestamp'] ?? '').toString();
              final outTime = (v['outTime'] ?? '').toString();
              final parsedIn = DateTime.tryParse(inTime);
              final parsedOut = outTime.isNotEmpty ? DateTime.tryParse(outTime) : null;
              final fmt = DateFormat('hh:mm a');

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
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.tertiaryContainer,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onTertiaryContainer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (purpose.isNotEmpty)
                              Text(purpose,
                                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                            Row(
                              children: [
                                Icon(Icons.login, size: 12, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  parsedIn != null ? fmt.format(parsedIn.toLocal()) : inTime,
                                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                ),
                                if (parsedOut != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.logout, size: 12, color: cs.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    fmt.format(parsedOut.toLocal()),
                                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
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
