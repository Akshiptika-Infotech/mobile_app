import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/providers/certificate_provider.dart';

class CertificatesIssuedScreen extends ConsumerWidget {
  const CertificatesIssuedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(certificateProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Issued Certificates'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(certificateProvider.notifier).load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIssueCertSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Issue Certificate'),
      ),
      body: Builder(builder: (context) {
        if (state.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AppSkeletonLoader.list(count: 8),
          );
        }
        if (state.error != null) {
          return AppErrorState(
            message: state.error!,
            onRetry: () => ref.read(certificateProvider.notifier).load(),
          );
        }
        if (state.certificates.isEmpty) {
          return const AppEmptyState(
            message: 'No certificates issued yet',
            icon: Icons.workspace_premium_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: state.certificates.length,
          itemBuilder: (_, i) {
            final cert = state.certificates[i];
            final parsedDate = DateTime.tryParse(cert.issueDate);
            final displayDate = parsedDate != null
                ? DateFormat('dd MMM yyyy').format(parsedDate.toLocal())
                : cert.issueDate;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.tertiaryContainer,
                  child: Icon(Icons.workspace_premium_outlined,
                      color: cs.onTertiaryContainer, size: 20),
                ),
                title: Text(
                  cert.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${cert.type}'),
                    Text(
                      displayDate,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('PDF download requires device package (Phase M9)')),
                    );
                  },
                  icon: Icon(Icons.share_outlined, color: cs.primary),
                  tooltip: 'Share/Download',
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showIssueCertSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _IssueCertSheet(notifier: ref.read(certificateProvider.notifier)),
    );
  }
}

// ── Issue Certificate Sheet ───────────────────────────────────────────────────

class _IssueCertSheet extends StatefulWidget {
  const _IssueCertSheet({required this.notifier});
  final CertificateNotifier notifier;

  @override
  State<_IssueCertSheet> createState() => _IssueCertSheetState();
}

class _IssueCertSheetState extends State<_IssueCertSheet> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _studentNameCtrl = TextEditingController();
  String _type = 'Bonafide';
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _types = ['Bonafide', 'Transfer', 'Character', 'Migration', 'Study', 'Other'];

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _studentNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.notifier.issue(
        studentId: _studentIdCtrl.text.trim(),
        type: _type,
        date: DateFormat('yyyy-MM-dd').format(_date),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Certificate issued')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || d == null) return;
    setState(() => _date = d);
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
            Text('Issue Certificate', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _studentIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _studentNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                  labelText: 'Certificate Type', border: OutlineInputBorder()),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(DateFormat('dd MMM yyyy').format(_date)),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Issue Certificate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
