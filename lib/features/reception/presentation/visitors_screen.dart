import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/reception/data/reception_repository.dart';
import 'package:mobile_app/features/reception/domain/reception_model.dart';
import 'package:mobile_app/features/reception/providers/reception_provider.dart';

class ReceptionVisitorsScreen extends ConsumerWidget {
  const ReceptionVisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final visitorsAsync = ref.watch(receptionVisitorsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Visitors'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(receptionVisitorsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterSheet(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Register Visitor'),
      ),
      body: visitorsAsync.when(
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
                  onPressed: () => ref.invalidate(receptionVisitorsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (visitors) => visitors.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
                    const SizedBox(height: 16),
                    Text('No visitors today',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: visitors.length,
                itemBuilder: (_, i) => _VisitorCard(visitor: visitors[i]),
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
      builder: (_) => _RegisterSheet(onRegistered: () {
        ref.invalidate(receptionVisitorsProvider);
        ref.invalidate(receptionDashboardProvider);
      }),
    );
  }
}

// ── Visitor card ──────────────────────────────────────────────────────────────

class _VisitorCard extends StatelessWidget {
  const _VisitorCard({required this.visitor});
  final ReceptionVisitor visitor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            child: Text(
              visitor.fullName.isNotEmpty
                  ? visitor.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                  fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visitor.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (visitor.phone.isNotEmpty)
                  Text(visitor.phone,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                if (visitor.purposeOfVisit.isNotEmpty)
                  Text(visitor.purposeOfVisit,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (visitor.personToMeet.isNotEmpty)
                  Row(children: [
                    Icon(Icons.person_rounded,
                        size: 11, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text('To meet: ${visitor.personToMeet}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  ]),
              ],
            ),
          ),
          if (visitor.date.isNotEmpty)
            Text(visitor.date,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Register bottom sheet ──────────────────────────────────────────────────────

class _RegisterSheet extends ConsumerStatefulWidget {
  const _RegisterSheet({required this.onRegistered});
  final VoidCallback onRegistered;

  @override
  ConsumerState<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends ConsumerState<_RegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _meetCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _purposeCtrl.dispose();
    _meetCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(receptionRepositoryProvider).registerVisitor(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            purposeOfVisit: _purposeCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            personToMeet: _meetCtrl.text.trim(),
            vehicleNumber: _vehicleCtrl.text.trim(),
          );
      widget.onRegistered();
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Register Visitor',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Full Name *', Icons.person_rounded,
                  required: true),
              const SizedBox(height: 10),
              _field(_phoneCtrl, 'Phone *', Icons.phone_rounded,
                  required: true, keyboard: TextInputType.phone),
              const SizedBox(height: 10),
              _field(_emailCtrl, 'Email', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  caps: TextCapitalization.none),
              const SizedBox(height: 10),
              _field(_purposeCtrl, 'Purpose of Visit *',
                  Icons.info_outline_rounded,
                  required: true),
              const SizedBox(height: 10),
              _field(_meetCtrl, 'Person to Meet', Icons.badge_rounded),
              const SizedBox(height: 10),
              _field(_vehicleCtrl, 'Vehicle Number',
                  Icons.directions_car_outlined,
                  caps: TextCapitalization.characters),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Register Visitor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
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
