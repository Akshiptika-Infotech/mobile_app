import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';

final _entryExitProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/admin/gate/entry-exit');
});

class EntryExitLogScreen extends ConsumerStatefulWidget {
  const EntryExitLogScreen({super.key});

  @override
  ConsumerState<EntryExitLogScreen> createState() => _EntryExitLogScreenState();
}

class _EntryExitLogScreenState extends ConsumerState<EntryExitLogScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_entryExitProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Entry/Exit Log'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_entryExitProvider),
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
          onRetry: () => ref.invalidate(_entryExitProvider),
        ),
        data: (items) {
          final q = _searchCtrl.text.trim().toLowerCase();
          final filtered = items.where((log) {
            final name = (log['personName'] ?? log['name'] ?? '').toString().toLowerCase();
            return q.isEmpty || name.contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (items.isEmpty)
                const Expanded(
                  child: AppEmptyState(
                    message: 'No entry/exit logs',
                    icon: Icons.swap_horiz_outlined,
                  ),
                )
              else
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('No results for "$q"',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final log = filtered[i];
                            final type = (log['type'] ?? 'entry').toString();
                            final isEntry = type == 'entry';
                            final time = (log['time'] ?? log['timestamp'] ?? '').toString();
                            final parsedTime = DateTime.tryParse(time);
                            final displayTime = parsedTime != null
                                ? DateFormat('dd MMM, hh:mm a').format(parsedTime.toLocal())
                                : time;

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isEntry
                                      ? cs.primaryContainer
                                      : cs.errorContainer,
                                  child: Icon(
                                    isEntry ? Icons.login : Icons.logout,
                                    color: isEntry ? cs.onPrimaryContainer : cs.onErrorContainer,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  (log['personName'] ?? log['name'] ?? '').toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${log['personType'] ?? ''} • $displayTime',
                                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                ),
                                trailing: Chip(
                                  label: Text(
                                    isEntry ? 'In' : 'Out',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isEntry ? cs.onPrimaryContainer : cs.onErrorContainer,
                                    ),
                                  ),
                                  backgroundColor: isEntry ? cs.primaryContainer : cs.errorContainer,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            );
                          },
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
