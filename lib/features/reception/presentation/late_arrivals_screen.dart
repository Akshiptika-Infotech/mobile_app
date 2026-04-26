import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/reception/data/reception_repository.dart';
import 'package:mobile_app/features/reception/domain/reception_model.dart';
import 'package:mobile_app/features/reception/providers/reception_provider.dart';

class LateArrivalsScreen extends ConsumerWidget {
  const LateArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final arrivalsAsync = ref.watch(lateArrivalsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Late Arrivals'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(lateArrivalsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterSheet(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Register'),
      ),
      body: arrivalsAsync.when(
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
                  onPressed: () => ref.invalidate(lateArrivalsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (arrivals) => arrivals.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
                    const SizedBox(height: 16),
                    Text('No late arrivals today',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: arrivals.length,
                itemBuilder: (_, i) => _ArrivalCard(arrival: arrivals[i]),
              ),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RegisterSheet(ref: ref),
    );
  }
}

class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({required this.arrival});
  final LateArrival arrival;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const color = Color(0xFFEF4444);

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
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                arrival.studentName.isNotEmpty
                    ? arrival.studentName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(arrival.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  '${arrival.className} ${arrival.section}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (arrival.reason.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(arrival.reason,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (arrival.arrivalTime.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(arrival.arrivalTime,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
              if (arrival.notifyParent) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.notifications_active_rounded,
                      size: 12, color: cs.primary),
                  const SizedBox(width: 3),
                  Text('Parent notified',
                      style: TextStyle(fontSize: 10, color: cs.primary)),
                ]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisterSheet extends StatefulWidget {
  const _RegisterSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _notifyParent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _sectionCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.ref.read(receptionRepositoryProvider).registerLateArrival(
            studentName: _nameCtrl.text.trim(),
            className: _classCtrl.text.trim(),
            section: _sectionCtrl.text.trim(),
            reason: _reasonCtrl.text.trim(),
            notifyParent: _notifyParent,
          );
      widget.ref.invalidate(lateArrivalsProvider);
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
            Text('Register Late Arrival',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _f(_nameCtrl, 'Student Name', Icons.person_rounded, required: true),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _f(_classCtrl, 'Class', Icons.class_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _f(_sectionCtrl, 'Section', Icons.abc_rounded)),
              ],
            ),
            const SizedBox(height: 10),
            _f(_reasonCtrl, 'Reason for Late', Icons.info_outline_rounded),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _notifyParent,
              onChanged: (v) => setState(() => _notifyParent = v),
              title: const Text('Notify Parent',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text('Send a notification to parent',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Register Late Arrival'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon,
      {bool required = false}) {
    return TextFormField(
      controller: c,
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
