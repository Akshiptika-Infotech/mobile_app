import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/security_model.dart';
import 'package:mobile_app/features/security/providers/security_provider.dart';

class EntryExitScreen extends ConsumerStatefulWidget {
  const EntryExitScreen({super.key});

  @override
  ConsumerState<EntryExitScreen> createState() => _EntryExitScreenState();
}

class _EntryExitScreenState extends ConsumerState<EntryExitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _personType = 'visitor';
  String _logType = 'entry';
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(securityRepositoryProvider).logEntryExit(
            personName: _nameCtrl.text.trim(),
            personType: _personType,
            type: _logType,
          );
      if (!mounted) return;
      ref.invalidate(securityDashboardProvider);
      ref.invalidate(entryExitLogProvider);
      _nameCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_logType == 'entry' ? 'Entry' : 'Exit'} logged successfully'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logAsync = ref.watch(entryExitLogProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Entry / Exit Log'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(entryExitLogProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Quick log form ──────────────────────────────────────────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Log',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Person Name',
                      prefixIcon: const Icon(Icons.person_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 12),
                  // Person type chips
                  Row(
                    children: ['student', 'staff', 'visitor'].map((t) {
                      final selected = _personType == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                              t[0].toUpperCase() + t.substring(1)),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _personType = t),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Entry / Exit toggle
                  Row(
                    children: [
                      Expanded(
                        child: _TypeToggle(
                          label: 'Entry',
                          icon: Icons.login_rounded,
                          color: const Color(0xFF10B981),
                          selected: _logType == 'entry',
                          onTap: () => setState(() => _logType = 'entry'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeToggle(
                          label: 'Exit',
                          icon: Icons.logout_rounded,
                          color: const Color(0xFF3B82F6),
                          selected: _logType == 'exit',
                          onTap: () => setState(() => _logType = 'exit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                          : Text('Log ${_logType == 'entry' ? 'Entry' : 'Exit'}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // ── Today's log ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text("Today's Log",
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: logAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: TextStyle(color: cs.error))),
              data: (records) => records.isEmpty
                  ? Center(
                      child: Text('No entries today',
                          style: TextStyle(color: cs.onSurfaceVariant)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: records.length,
                      itemBuilder: (_, i) =>
                          _RecordTile(record: records[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? color : color.withValues(alpha: 0.5),
                size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? color : color.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final EntryExitRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEntry = record.type == 'entry';
    final color = isEntry ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
                isEntry ? Icons.login_rounded : Icons.logout_rounded,
                color: color,
                size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.personName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${record.personType[0].toUpperCase()}${record.personType.substring(1)}',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEntry ? 'Entry' : 'Exit',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
              if (record.time.isNotEmpty)
                Text(record.time,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
