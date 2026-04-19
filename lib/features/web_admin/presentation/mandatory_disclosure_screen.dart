import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/web_admin/data/web_admin_repository.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';

// ── Providers (local, auto-dispose) ───────────────────────────────────────────

final _generalInfoProvider = FutureProvider.autoDispose<MandatoryGeneralInfo>(
  (ref) => ref.read(webAdminRepositoryProvider).fetchMandatoryGeneralInfo(),
);

final _staffProvider = FutureProvider.autoDispose<MandatoryStaff>(
  (ref) => ref.read(webAdminRepositoryProvider).fetchMandatoryStaff(),
);

final _infraProvider = FutureProvider.autoDispose<MandatoryInfrastructure>(
  (ref) => ref.read(webAdminRepositoryProvider).fetchMandatoryInfrastructure(),
);

final _resultsProvider = FutureProvider.autoDispose<List<MandatoryResult>>(
  (ref) => ref.read(webAdminRepositoryProvider).fetchMandatoryResults(),
);

// ── Main screen ───────────────────────────────────────────────────────────────

class MandatoryDisclosureScreen extends ConsumerStatefulWidget {
  const MandatoryDisclosureScreen({super.key});

  @override
  ConsumerState<MandatoryDisclosureScreen> createState() =>
      _MandatoryDisclosureScreenState();
}

class _MandatoryDisclosureScreenState
    extends ConsumerState<MandatoryDisclosureScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mandatory Disclosure'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'General Info'),
            Tab(text: 'Staff'),
            Tab(text: 'Infrastructure'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _GeneralInfoTab(),
          _StaffTab(),
          _InfrastructureTab(),
          _ResultsTab(),
        ],
      ),
    );
  }
}

// ── General Info Tab ──────────────────────────────────────────────────────────

class _GeneralInfoTab extends ConsumerWidget {
  const _GeneralInfoTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_generalInfoProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: e.toString(),
        onRetry: () => ref.invalidate(_generalInfoProvider),
      ),
      data: (info) => _GeneralInfoForm(info: info),
    );
  }
}

class _GeneralInfoForm extends ConsumerStatefulWidget {
  const _GeneralInfoForm({required this.info});
  final MandatoryGeneralInfo info;

  @override
  ConsumerState<_GeneralInfoForm> createState() => _GeneralInfoFormState();
}

class _GeneralInfoFormState extends ConsumerState<_GeneralInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _affNo;
  late final TextEditingController _code;
  late final TextEditingController _address;
  late final TextEditingController _principal;
  late final TextEditingController _qualification;
  late final TextEditingController _email;
  late final TextEditingController _phones;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.info.schoolName);
    _affNo = TextEditingController(text: widget.info.affiliationNo);
    _code = TextEditingController(text: widget.info.schoolCode);
    _address = TextEditingController(text: widget.info.address);
    _principal = TextEditingController(text: widget.info.principalName);
    _qualification =
        TextEditingController(text: widget.info.principalQualification);
    _email = TextEditingController(text: widget.info.schoolEmail);
    _phones = TextEditingController(
        text: widget.info.contactNumbers.join(', '));
  }

  @override
  void dispose() {
    for (final c in [_name, _affNo, _code, _address, _principal, _qualification, _email, _phones]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final phones = _phones.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ref.read(webAdminRepositoryProvider).saveMandatoryGeneralInfo({
        'schoolName': _name.text.trim(),
        'affiliationNo': _affNo.text.trim(),
        'schoolCode': _code.text.trim(),
        'address': _address.text.trim(),
        'principalName': _principal.text.trim(),
        'principalQualification': _qualification.text.trim(),
        'schoolEmail': _email.text.trim(),
        'contactNumbers': phones,
      });
      ref.invalidate(_generalInfoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('General info saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _field(_name, 'School Name *', required: true),
          _field(_affNo, 'Affiliation Number'),
          _field(_code, 'School Code'),
          _field(_address, 'Address', maxLines: 3),
          _field(_principal, 'Principal Name *', required: true),
          _field(_qualification, 'Principal Qualification'),
          _field(_email, 'School Email', keyboard: TextInputType.emailAddress),
          _field(_phones, 'Contact Numbers', hint: 'Comma separated, e.g. 98765, 87654'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save General Info'),
          ),
        ]),
      ),
    );
  }
}

// ── Staff Tab ─────────────────────────────────────────────────────────────────

class _StaffTab extends ConsumerWidget {
  const _StaffTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_staffProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: e.toString(),
        onRetry: () => ref.invalidate(_staffProvider),
      ),
      data: (staff) => _StaffForm(staff: staff),
    );
  }
}

class _StaffForm extends ConsumerStatefulWidget {
  const _StaffForm({required this.staff});
  final MandatoryStaff staff;

  @override
  ConsumerState<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<_StaffForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _principal;
  late final TextEditingController _total;
  late final TextEditingController _pgt;
  late final TextEditingController _tgt;
  late final TextEditingController _prt;
  late final TextEditingController _ratio;
  late final TextEditingController _special;
  late final TextEditingController _counsellor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _principal = TextEditingController(text: widget.staff.principalName);
    _total = TextEditingController(text: widget.staff.totalTeachers.toString());
    _pgt = TextEditingController(text: widget.staff.pgt?.toString() ?? '');
    _tgt = TextEditingController(text: widget.staff.tgt?.toString() ?? '');
    _prt = TextEditingController(text: widget.staff.prt?.toString() ?? '');
    _ratio = TextEditingController(text: widget.staff.teacherSectionRatio);
    _special = TextEditingController(text: widget.staff.specialEducator);
    _counsellor = TextEditingController(text: widget.staff.counsellorDetails);
  }

  @override
  void dispose() {
    for (final c in [_principal, _total, _pgt, _tgt, _prt, _ratio, _special, _counsellor]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(webAdminRepositoryProvider).saveMandatoryStaff({
        'principalName': _principal.text.trim(),
        'totalTeachers': int.tryParse(_total.text) ?? 0,
        if (_pgt.text.isNotEmpty) 'pgt': int.tryParse(_pgt.text),
        if (_tgt.text.isNotEmpty) 'tgt': int.tryParse(_tgt.text),
        if (_prt.text.isNotEmpty) 'prt': int.tryParse(_prt.text),
        'teacherSectionRatio': _ratio.text.trim(),
        'specialEducator': _special.text.trim(),
        'counsellorDetails': _counsellor.text.trim(),
      });
      ref.invalidate(_staffProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Staff info saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _field(_principal, 'Principal Name'),
          _field(_total, 'Total Teachers', keyboard: TextInputType.number),
          Row(children: [
            Expanded(child: _field(_pgt, 'PGT', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_tgt, 'TGT', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_prt, 'PRT', keyboard: TextInputType.number)),
          ]),
          _field(_ratio, 'Teacher-Section Ratio'),
          _field(_special, 'Special Educator'),
          _field(_counsellor, 'Counsellor Details', maxLines: 3),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Staff Info'),
          ),
        ]),
      ),
    );
  }
}

// ── Infrastructure Tab ────────────────────────────────────────────────────────

class _InfrastructureTab extends ConsumerWidget {
  const _InfrastructureTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_infraProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: e.toString(),
        onRetry: () => ref.invalidate(_infraProvider),
      ),
      data: (infra) => _InfraForm(infra: infra),
    );
  }
}

class _InfraForm extends ConsumerStatefulWidget {
  const _InfraForm({required this.infra});
  final MandatoryInfrastructure infra;

  @override
  ConsumerState<_InfraForm> createState() => _InfraFormState();
}

class _InfraFormState extends ConsumerState<_InfraForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _campus;
  late final TextEditingController _classCount;
  late final TextEditingController _classSize;
  late final TextEditingController _labCount;
  late final TextEditingController _labSize;
  late final TextEditingController _girls;
  late final TextEditingController _boys;
  late final TextEditingController _youtube;
  late bool _internet;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _campus = TextEditingController(text: widget.infra.campusArea);
    _classCount = TextEditingController(text: widget.infra.classroomCount?.toString() ?? '');
    _classSize = TextEditingController(text: widget.infra.classroomSize);
    _labCount = TextEditingController(text: widget.infra.labCount?.toString() ?? '');
    _labSize = TextEditingController(text: widget.infra.labSize);
    _girls = TextEditingController(text: widget.infra.girlsToilets?.toString() ?? '');
    _boys = TextEditingController(text: widget.infra.boysToilets?.toString() ?? '');
    _youtube = TextEditingController(text: widget.infra.youtubeLink);
    _internet = widget.infra.internetFacility;
  }

  @override
  void dispose() {
    for (final c in [_campus, _classCount, _classSize, _labCount, _labSize, _girls, _boys, _youtube]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(webAdminRepositoryProvider).saveMandatoryInfrastructure({
        'campusArea': _campus.text.trim(),
        if (_classCount.text.isNotEmpty) 'classroomCount': int.tryParse(_classCount.text),
        'classroomSize': _classSize.text.trim(),
        if (_labCount.text.isNotEmpty) 'labCount': int.tryParse(_labCount.text),
        'labSize': _labSize.text.trim(),
        'internetFacility': _internet,
        if (_girls.text.isNotEmpty) 'girlsToilets': int.tryParse(_girls.text),
        if (_boys.text.isNotEmpty) 'boysToilets': int.tryParse(_boys.text),
        'youtubeLink': _youtube.text.trim(),
      });
      ref.invalidate(_infraProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Infrastructure info saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _field(_campus, 'Campus Area (sq. meters/acres)'),
          Row(children: [
            Expanded(child: _field(_classCount, 'Classrooms', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_classSize, 'Classroom Size (sq.m)')),
          ]),
          Row(children: [
            Expanded(child: _field(_labCount, 'Labs', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_labSize, 'Lab Size (sq.m)')),
          ]),
          Row(children: [
            Expanded(child: _field(_girls, 'Girls Toilets', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field(_boys, 'Boys Toilets', keyboard: TextInputType.number)),
          ]),
          SwitchListTile(
            value: _internet,
            onChanged: (v) => setState(() => _internet = v),
            title: const Text('Internet Facility'),
            contentPadding: EdgeInsets.zero,
          ),
          _field(_youtube, 'YouTube Link (inspection video)'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Infrastructure'),
          ),
        ]),
      ),
    );
  }
}

// ── Results Tab ───────────────────────────────────────────────────────────────

class _ResultsTab extends ConsumerWidget {
  const _ResultsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_resultsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: e.toString(),
        onRetry: () => ref.invalidate(_resultsProvider),
      ),
      data: (results) => _ResultsList(results: results),
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.results});
  final List<MandatoryResult> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: results.isEmpty
          ? Center(
              child: Text('No results yet.',
                  style: TextStyle(color: cs.onSurfaceVariant)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, i) {
                final r = results[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text('Class ${r.className} — ${r.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Registered: ${r.registeredStudents}  |  Passed: ${r.studentsPassed}  |  ${r.passPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: cs.error),
                      onPressed: () => _delete(context, ref, r),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddResult(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, MandatoryResult r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Result'),
        content: Text('Delete result for Class ${r.className} (${r.year})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(webAdminRepositoryProvider).deleteMandatoryResult(r.id);
      ref.invalidate(_resultsProvider);
    }
  }

  Future<void> _showAddResult(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddResultSheet(ref: ref),
    );
  }
}

class _AddResultSheet extends ConsumerStatefulWidget {
  const _AddResultSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_AddResultSheet> createState() => _AddResultSheetState();
}

class _AddResultSheetState extends ConsumerState<_AddResultSheet> {
  final _formKey = GlobalKey<FormState>();
  final _class = TextEditingController();
  final _year = TextEditingController();
  final _registered = TextEditingController();
  final _passed = TextEditingController();
  final _pct = TextEditingController();
  final _remarks = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_class, _year, _registered, _passed, _pct, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(webAdminRepositoryProvider).createMandatoryResult({
        'class': _class.text.trim(),
        'year': _year.text.trim(),
        'registeredStudents': int.tryParse(_registered.text) ?? 0,
        'studentsPassed': int.tryParse(_passed.text) ?? 0,
        'passPercentage': double.tryParse(_pct.text) ?? 0.0,
        'remarks': _remarks.text.trim(),
      });
      ref.invalidate(_resultsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Add Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field(_class, 'Class *', required: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_year, 'Year *', required: true,
                  hint: 'e.g. 2024')),
            ]),
            Row(children: [
              Expanded(child: _field(_registered, 'Registered',
                  keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(_passed, 'Passed',
                      keyboard: TextInputType.number)),
            ]),
            _field(_pct, 'Pass %',
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
            _field(_remarks, 'Remarks', maxLines: 2),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Add Result'),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _field(
  TextEditingController ctrl,
  String label, {
  bool required = false,
  int maxLines = 1,
  String? hint,
  TextInputType keyboard = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
              maxLines: 3),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}
