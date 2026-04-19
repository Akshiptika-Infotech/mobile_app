import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/data/transport_repository.dart';
import 'package:mobile_app/features/admin/providers/transport_admin_provider.dart';

class TransportAssignmentsScreen extends ConsumerStatefulWidget {
  const TransportAssignmentsScreen({super.key});

  @override
  ConsumerState<TransportAssignmentsScreen> createState() => _TransportAssignmentsScreenState();
}

class _TransportAssignmentsScreenState extends ConsumerState<TransportAssignmentsScreen> {
  final _studentCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  final _stopCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _studentCtrl.dispose();
    _routeCtrl.dispose();
    _stopCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_studentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportAdminRepositoryProvider).createAssignment({
        'studentId': _studentCtrl.text.trim(),
        'routeId': _routeCtrl.text.trim(),
        'stoppageId': _stopCtrl.text.trim(),
      });
      _studentCtrl.clear();
      _routeCtrl.clear();
      _stopCtrl.clear();
      ref.invalidate(transportAssignmentsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAdd() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _studentCtrl,
              decoration: const InputDecoration(labelText: 'Student ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _routeCtrl,
              decoration: const InputDecoration(labelText: 'Route ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stopCtrl,
              decoration: const InputDecoration(labelText: 'Stoppage ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        await _add();
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(transportAssignmentsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Transport Assignments'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        child: const Icon(Icons.add),
      ),
      body: list.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 6),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(transportAssignmentsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No assignments found',
              icon: Icons.directions_bus_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final a = items[i];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ListTile(
                  title: Text(a.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Route: ${a.routeName}\nStop: ${a.stoppageName}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
