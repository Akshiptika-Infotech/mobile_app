import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/reception/data/reception_repository.dart';
import 'package:mobile_app/features/reception/domain/reception_model.dart';
import 'package:mobile_app/features/reception/providers/reception_provider.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final apptAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Appointments'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(appointmentsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Appointment'),
      ),
      body: apptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                    maxLines: 3),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(appointmentsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (appts) {
          if (appts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
                  const SizedBox(height: 16),
                  Text('No appointments',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }
          final scheduled = appts.where((a) => a.status == 'scheduled').toList();
          final others = appts.where((a) => a.status != 'scheduled').toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              if (scheduled.isNotEmpty) ...[
                _SectionLabel('Upcoming (${scheduled.length})'),
                const SizedBox(height: 8),
                ...scheduled.map((a) => _ApptCard(appt: a, ref: ref)),
                const SizedBox(height: 16),
              ],
              if (others.isNotEmpty) ...[
                _SectionLabel('Past (${others.length})'),
                const SizedBox(height: 8),
                ...others.map((a) => _ApptCard(appt: a, ref: ref)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateApptSheet(ref: ref),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _ApptCard extends StatelessWidget {
  const _ApptCard({required this.appt, required this.ref});
  final Appointment appt;
  final WidgetRef ref;

  static const _statusColors = {
    'scheduled': Color(0xFF3B82F6),
    'completed': Color(0xFF10B981),
    'cancelled': Color(0xFF6B7280),
  };

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      await ref.read(receptionRepositoryProvider).updateAppointmentStatus(appt.id, status);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(receptionDashboardProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColors[appt.status] ?? Colors.grey;
    final isScheduled = appt.status == 'scheduled';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.visitorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    if (appt.hostName.isNotEmpty)
                      Text('To meet: ${appt.hostName}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  appt.status[0].toUpperCase() + appt.status.substring(1),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
            ],
          ),
          if (appt.purpose.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(appt.purpose,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
          if (appt.scheduledAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.schedule_rounded, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(appt.scheduledAt,
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ],
          if (isScheduled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, 'completed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('Complete', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateApptSheet extends StatefulWidget {
  const _CreateApptSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateApptSheet> createState() => _CreateApptSheetState();
}

class _CreateApptSheetState extends State<_CreateApptSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  DateTime? _scheduledAt;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _purposeCtrl.dispose();
    _hostCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date & time')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.ref.read(receptionRepositoryProvider).createAppointment(
            visitorName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            purpose: _purposeCtrl.text.trim(),
            hostName: _hostCtrl.text.trim(),
            scheduledAt: _scheduledAt!.toIso8601String(),
          );
      widget.ref.invalidate(appointmentsProvider);
      widget.ref.invalidate(receptionDashboardProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('New Appointment',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _f(_nameCtrl, 'Visitor Name', Icons.person_rounded, required: true),
              const SizedBox(height: 10),
              _f(_phoneCtrl, 'Phone', Icons.phone_rounded,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 10),
              _f(_purposeCtrl, 'Purpose', Icons.info_outline_rounded,
                  required: true),
              const SizedBox(height: 10),
              _f(_hostCtrl, 'Person to Meet', Icons.badge_rounded),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _scheduledAt == null
                            ? 'Select Date & Time'
                            : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}  ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _scheduledAt == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Create Appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon,
      {bool required = false, TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
