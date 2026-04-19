import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/student_model.dart';
import 'package:mobile_app/features/admin/providers/student_provider.dart';

class StudentEditScreen extends ConsumerStatefulWidget {
  const StudentEditScreen({super.key, required this.studentId});
  final String studentId;

  @override
  ConsumerState<StudentEditScreen> createState() => _StudentEditScreenState();
}

class _StudentEditScreenState extends ConsumerState<StudentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialised = false;

  // Personal
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String? _bloodGroup;
  final _religionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Academic
  String? _className;
  final _sectionCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _admissionCtrl = TextEditingController();
  final _academicYearCtrl = TextEditingController();

  // Parent
  final _fatherNameCtrl = TextEditingController();
  final _fatherPhoneCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherPhoneCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  static const _classes = [
    'Pre-KG', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _religionCtrl.dispose();
    _categoryCtrl.dispose();
    _houseCtrl.dispose();
    _addressCtrl.dispose();
    _sectionCtrl.dispose();
    _rollCtrl.dispose();
    _admissionCtrl.dispose();
    _academicYearCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherPhoneCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherPhoneCtrl.dispose();
    _parentEmailCtrl.dispose();
    super.dispose();
  }

  void _populate(StudentModel s) {
    if (_initialised) return;
    _initialised = true;
    _nameCtrl.text = s.name;
    _religionCtrl.text = s.religion ?? '';
    _categoryCtrl.text = s.category ?? '';
    _houseCtrl.text = s.house ?? '';
    _addressCtrl.text = s.address ?? '';
    _sectionCtrl.text = s.section;
    _rollCtrl.text = s.rollNumber;
    _admissionCtrl.text = s.admissionNumber;
    _academicYearCtrl.text = s.academicYear ?? '';
    _fatherNameCtrl.text = s.fatherName ?? '';
    _fatherPhoneCtrl.text = s.fatherPhone ?? '';
    _motherNameCtrl.text = s.motherName ?? '';
    _motherPhoneCtrl.text = s.motherPhone ?? '';
    _parentEmailCtrl.text = s.parentEmail ?? '';
    setState(() {
      _gender = _genders.contains(s.gender) ? s.gender : null;
      _bloodGroup = _bloodGroups.contains(s.bloodGroup) ? s.bloodGroup : null;
      _className = _classes.contains(s.className) ? s.className : null;
      if (s.dob != null) {
        _dob = DateTime.tryParse(s.dob!);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'name': _nameCtrl.text.trim(),
      if (_dob != null) 'dob': _dob!.toIso8601String().split('T').first,
      if (_gender != null) 'gender': _gender,
      if (_bloodGroup != null) 'bloodGroup': _bloodGroup,
      if (_religionCtrl.text.isNotEmpty) 'religion': _religionCtrl.text.trim(),
      if (_categoryCtrl.text.isNotEmpty) 'category': _categoryCtrl.text.trim(),
      if (_houseCtrl.text.isNotEmpty) 'house': _houseCtrl.text.trim(),
      if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
      if (_className != null) 'class': _className,
      if (_sectionCtrl.text.isNotEmpty) 'section': _sectionCtrl.text.trim(),
      if (_rollCtrl.text.isNotEmpty) 'rollNumber': _rollCtrl.text.trim(),
      if (_admissionCtrl.text.isNotEmpty)
        'admissionNumber': _admissionCtrl.text.trim(),
      if (_academicYearCtrl.text.isNotEmpty)
        'academicYear': _academicYearCtrl.text.trim(),
      if (_fatherNameCtrl.text.isNotEmpty)
        'fatherName': _fatherNameCtrl.text.trim(),
      if (_fatherPhoneCtrl.text.isNotEmpty)
        'fatherPhone': _fatherPhoneCtrl.text.trim(),
      if (_motherNameCtrl.text.isNotEmpty)
        'motherName': _motherNameCtrl.text.trim(),
      if (_motherPhoneCtrl.text.isNotEmpty)
        'motherPhone': _motherPhoneCtrl.text.trim(),
      if (_parentEmailCtrl.text.isNotEmpty)
        'parentEmail': _parentEmailCtrl.text.trim(),
    };
    await ref
        .read(studentFormProvider.notifier)
        .update(widget.studentId, payload);
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync =
        ref.watch(studentDetailProvider(widget.studentId));
    final formState = ref.watch(studentFormProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen(studentFormProvider, (_, next) {
      if (next.success) {
        ref.read(studentFormProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student updated successfully.')),
        );
        context.pop();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref.read(studentFormProvider.notifier).reset();
      }
    });

    return studentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Student')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (student) {
        _populate(student);
        return Scaffold(
          appBar: AppBar(
            title: Text('Edit — ${student.name}'),
            actions: [
              if (formState.isSubmitting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                      child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('Personal Information', Icons.person_outline),
                _field(_nameCtrl, 'Full Name', required: true),
                _dobPicker(cs),
                _dropdown('Gender', _genders, _gender,
                    (v) => setState(() => _gender = v)),
                _dropdown('Blood Group', _bloodGroups, _bloodGroup,
                    (v) => setState(() => _bloodGroup = v)),
                _field(_religionCtrl, 'Religion'),
                _field(_categoryCtrl, 'Category'),
                _field(_houseCtrl, 'House'),
                _field(_addressCtrl, 'Address', maxLines: 2),

                const SizedBox(height: 8),
                _section('Academic Information', Icons.school_outlined),
                _dropdown('Class', _classes, _className,
                    (v) => setState(() => _className = v), required: true),
                _field(_sectionCtrl, 'Section'),
                _field(_rollCtrl, 'Roll Number'),
                _field(_admissionCtrl, 'Admission Number'),
                _field(_academicYearCtrl, 'Academic Year'),

                const SizedBox(height: 8),
                _section('Parent / Guardian', Icons.family_restroom_outlined),
                _field(_fatherNameCtrl, 'Father Name'),
                _field(_fatherPhoneCtrl, 'Father Phone',
                    type: TextInputType.phone),
                _field(_motherNameCtrl, 'Mother Name'),
                _field(_motherPhoneCtrl, 'Mother Phone',
                    type: TextInputType.phone),
                _field(_parentEmailCtrl, 'Parent Email',
                    type: TextInputType.emailAddress),

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: formState.isSubmitting ? null : _save,
                  icon: formState.isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(child: Divider(
                color: Theme.of(context).colorScheme.outlineVariant)),
          ],
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType? type,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      );

  Widget _dobPicker(ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dob ?? DateTime(2010),
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dob = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              border: OutlineInputBorder(),
              filled: true,
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              _dob != null
                  ? DateFormat('dd MMM yyyy').format(_dob!)
                  : 'Select date',
              style: TextStyle(
                  color: _dob != null ? null : cs.onSurfaceVariant),
            ),
          ),
        ),
      );

  Widget _dropdown(
    String label,
    List<String> options,
    String? value,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
          validator:
              required ? (v) => v == null ? 'Required' : null : null,
        ),
      );
}
