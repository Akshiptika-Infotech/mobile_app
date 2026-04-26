import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/data/admin_views_repository.dart';

final _receptionAppointmentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminViewsRepositoryProvider).fetchList('/api/reception/appointments');
});

class ReceptionAppointmentsAdminScreen extends ConsumerWidget {
  const ReceptionAppointmentsAdminScreen({super.key});

  Future<void> _cancel(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Cancel Appointment',
      message: 'Are you sure you want to cancel this appointment?',
      confirmLabel: 'Cancel Appointment',
      isDestructive: true,
    );
    if (confirm != true) return;
    try {
      await ref
          .read(adminViewsRepositoryProvider)
          .patch('/api/reception/appointments/$id', {'status': 'cancelled'});
      ref.invalidate(_receptionAppointmentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddAppointmentSheet(
        onAdded: () => ref.invalidate(_receptionAppointmentsProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final data = ref.watch(_receptionAppointmentsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_receptionAppointmentsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: data.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 8),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_receptionAppointmentsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppEmptyState(
                  message: 'No appointments',
                  icon: Icons.event_note_outlined,
                ),
                FilledButton.icon(
                  onPressed: () => _showAddSheet(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Appointment'),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final a = items[i];
              final id = (a['id'] ?? '').toString();
              final status = (a['status'] ?? '').toString();
              final scheduledAt = (a['scheduledAt'] ?? '').toString();
              final parsedAt = DateTime.tryParse(scheduledAt);
              final displayAt = parsedAt != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(parsedAt.toLocal())
                  : scheduledAt;
              final isCancelled = status == 'cancelled';

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
                        child: Icon(Icons.event_note_outlined,
                            color: cs.onSecondaryContainer, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (a['visitorName'] ?? a['name'] ?? '').toString(),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            if ((a['hostName'] ?? '').toString().isNotEmpty)
                              Text(
                                'Host: ${a['hostName']}',
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            if (displayAt.isNotEmpty)
                              Text(
                                displayAt,
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            if (status.isNotEmpty)
                              Chip(
                                label: Text(status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isCancelled ? cs.onErrorContainer : cs.onPrimaryContainer,
                                    )),
                                backgroundColor:
                                    isCancelled ? cs.errorContainer : cs.primaryContainer,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ),
                      if (!isCancelled && id.isNotEmpty)
                        IconButton(
                          onPressed: () => _cancel(context, ref, id),
                          icon: Icon(Icons.cancel_outlined, color: cs.error),
                          tooltip: 'Cancel',
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

// ── Add Appointment Sheet ─────────────────────────────────────────────────────

class _AddAppointmentSheet extends ConsumerStatefulWidget {
  const _AddAppointmentSheet({required this.onAdded});
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends ConsumerState<_AddAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _visitorCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;

  @override
  void dispose() {
    _visitorCtrl.dispose();
    _hostCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (!mounted || time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminViewsRepositoryProvider).post(
        '/api/reception/appointments',
        {
          'visitorName': _visitorCtrl.text.trim(),
          'hostName': _hostCtrl.text.trim(),
          'purpose': _purposeCtrl.text.trim(),
          'scheduledAt': _scheduledAt.toIso8601String(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Appointment added')));
      widget.onAdded();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Appointment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _visitorCtrl,
              decoration: const InputDecoration(labelText: 'Visitor Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _hostCtrl,
              decoration: const InputDecoration(labelText: 'Host / Person to Meet', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _purposeCtrl,
              decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(DateFormat('dd MMM yyyy, hh:mm a').format(_scheduledAt)),
              trailing: TextButton(onPressed: _pickDateTime, child: const Text('Change')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
