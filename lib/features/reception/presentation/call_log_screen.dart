import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/reception/data/reception_repository.dart';
import 'package:mobile_app/features/reception/domain/reception_model.dart';
import 'package:mobile_app/features/reception/providers/reception_provider.dart';

class CallLogScreen extends ConsumerWidget {
  const CallLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final logsAsync = ref.watch(callLogProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Call Log'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(callLogProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSheet(context, ref),
        icon: const Icon(Icons.add_call),
        label: const Text('Log Call'),
      ),
      body: logsAsync.when(
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
                  onPressed: () => ref.invalidate(callLogProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (logs) => logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
                    const SizedBox(height: 16),
                    Text('No calls logged today',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: logs.length,
                itemBuilder: (_, i) => _CallTile(log: logs[i]),
              ),
      ),
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LogCallSheet(ref: ref),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.log});
  final CallLog log;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const color = Color(0xFF10B981);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(log.callerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    if (log.time.isNotEmpty)
                      Text(log.time,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
                if (log.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(log.phone,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
                if (log.purpose.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Purpose: ${log.purpose}',
                      style: const TextStyle(fontSize: 12)),
                ],
                if (log.actionTaken.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 12, color: color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(log.actionTaken,
                          style: const TextStyle(fontSize: 12, color: color)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCallSheet extends StatefulWidget {
  const _LogCallSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_LogCallSheet> createState() => _LogCallSheetState();
}

class _LogCallSheetState extends State<_LogCallSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _purposeCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.ref.read(receptionRepositoryProvider).logCall(
            callerName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            purpose: _purposeCtrl.text.trim(),
            actionTaken: _actionCtrl.text.trim(),
          );
      widget.ref.invalidate(callLogProvider);
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
            Text('Log Incoming Call',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _f(_nameCtrl, 'Caller Name', Icons.person_rounded, required: true),
            const SizedBox(height: 10),
            _f(_phoneCtrl, 'Phone Number', Icons.phone_rounded,
                keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _f(_purposeCtrl, 'Purpose / Query', Icons.help_outline_rounded,
                required: true),
            const SizedBox(height: 10),
            _f(_actionCtrl, 'Action Taken', Icons.check_circle_outline_rounded),
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
                    : const Text('Save Call Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon,
      {bool required = false, TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}
