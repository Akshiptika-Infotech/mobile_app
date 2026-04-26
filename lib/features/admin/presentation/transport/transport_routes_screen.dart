import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/data/transport_repository.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/transport_admin_provider.dart';

class TransportRoutesScreen extends ConsumerStatefulWidget {
  const TransportRoutesScreen({super.key});

  @override
  ConsumerState<TransportRoutesScreen> createState() => _TransportRoutesScreenState();
}

class _TransportRoutesScreenState extends ConsumerState<TransportRoutesScreen> {
  final _nameCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportAdminRepositoryProvider).createRoute({
        'name': _nameCtrl.text.trim(),
        'vehicleNumber': _vehicleCtrl.text.trim(),
        'driverName': _driverCtrl.text.trim(),
      });
      _nameCtrl.clear();
      _vehicleCtrl.clear();
      _driverCtrl.clear();
      ref.invalidate(transportRoutesProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmDelete() =>
      ConfirmationDialog.show(
        context,
        title: 'Delete Route',
        message: 'This cannot be undone.',
        confirmLabel: 'Delete',
        isDestructive: true,
      );

  Future<void> _delete(String id) async {
    try {
      await ref.read(transportAdminRepositoryProvider).deleteRoute(id);
      ref.invalidate(transportRoutesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(transportRoutesProvider);
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Transport Routes'),
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
          onRetry: () => ref.invalidate(transportRoutesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No routes found',
              icon: Icons.route_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final route = items[i];
              return Dismissible(
                key: ValueKey(route.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) { HapticFeedback.mediumImpact(); return _confirmDelete(); },
                onDismissed: (_) => _delete(route.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
                ),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: ExpansionTile(
                    title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Vehicle: ${route.vehicleNumber}  Driver: ${route.driverName}'),
                    children: route.stoppages
                        .map(
                          (s) => ListTile(
                            dense: true,
                            title: Text('${s.order}. ${s.name}'),
                            trailing: Text(money.format(s.fee)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Route Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vehicleCtrl,
              decoration: const InputDecoration(labelText: 'Vehicle Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _driverCtrl,
              decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder()),
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
}
