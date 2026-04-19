import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/providers/student_provider.dart';

class StudentAddScreen extends ConsumerStatefulWidget {
  const StudentAddScreen({super.key});

  @override
  ConsumerState<StudentAddScreen> createState() => _StudentAddScreenState();
}

class _StudentAddScreenState extends ConsumerState<StudentAddScreen> {
  int _currentStep = 0;

  // Step 1 – Personal
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String? _bloodGroup;
  final _religionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Step 2 – Academic
  String? _className;
  final _sectionCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _admissionCtrl = TextEditingController();
  final _academicYearCtrl = TextEditingController();

  // Step 3 – Parent
  final _fatherNameCtrl = TextEditingController();
  final _fatherPhoneCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherPhoneCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

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

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      case 2:
        return _step3Key.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  Map<String, dynamic> _buildPayload() => {
        'name': _nameCtrl.text.trim(),
        if (_dob != null) 'dob': DateFormat('yyyy-MM-dd').format(_dob!),
        if (_gender != null) 'gender': _gender,
        if (_bloodGroup != null) 'bloodGroup': _bloodGroup,
        'religion': _religionCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'house': _houseCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'class': _className ?? '',
        'section': _sectionCtrl.text.trim(),
        'rollNumber': _rollCtrl.text.trim(),
        'admissionNumber': _admissionCtrl.text.trim(),
        'academicYear': _academicYearCtrl.text.trim(),
        'fatherName': _fatherNameCtrl.text.trim(),
        'fatherPhone': _fatherPhoneCtrl.text.trim(),
        'motherName': _motherNameCtrl.text.trim(),
        'motherPhone': _motherPhoneCtrl.text.trim(),
        'parentEmail': _parentEmailCtrl.text.trim(),
        'status': 'active',
      };

  Future<void> _submit() async {
    await ref.read(studentFormProvider.notifier).create(_buildPayload());
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(studentFormProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(studentFormProvider, (_, next) {
      if (next.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')),
        );
        context.pop();
      }
      if (next.error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: colorScheme.error,
          ),
        );
        ref.read(studentFormProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepCancel: _currentStep > 0
            ? () => setState(() => _currentStep--)
            : null,
        onStepContinue: () {
          if (_currentStep < 3) {
            if (_validateCurrentStep()) {
              setState(() => _currentStep++);
            }
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (!isLast)
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continue'),
                  )
                else
                  FilledButton(
                    onPressed: formState.isSubmitting ? null : _submit,
                    child: formState.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Personal'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0
                ? StepState.complete
                : StepState.indexed,
            content: Form(
              key: _step1Key,
              child: Column(
                children: [
                  _field(_nameCtrl, 'Full Name',
                      validator: _required),
                  _datePicker(context, 'Date of Birth', _dob, (d) {
                    setState(() => _dob = d);
                  }),
                  _dropdown('Gender', _genders, _gender,
                      (v) => setState(() => _gender = v)),
                  _dropdown('Blood Group', _bloodGroups, _bloodGroup,
                      (v) => setState(() => _bloodGroup = v)),
                  _field(_religionCtrl, 'Religion'),
                  _field(_categoryCtrl, 'Category'),
                  _field(_houseCtrl, 'House'),
                  _field(_addressCtrl, 'Address', maxLines: 3),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Academic'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1
                ? StepState.complete
                : StepState.indexed,
            content: Form(
              key: _step2Key,
              child: Column(
                children: [
                  _dropdown('Class', _classes, _className,
                      (v) => setState(() => _className = v),
                      required: true),
                  _field(_sectionCtrl, 'Section', validator: _required),
                  _field(_rollCtrl, 'Roll Number', validator: _required),
                  _field(_admissionCtrl, 'Admission Number',
                      validator: _required),
                  _field(_academicYearCtrl, 'Academic Year (e.g. 2024-25)'),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Parent'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2
                ? StepState.complete
                : StepState.indexed,
            content: Form(
              key: _step3Key,
              child: Column(
                children: [
                  _field(_fatherNameCtrl, "Father's Name",
                      validator: _required),
                  _field(_fatherPhoneCtrl, "Father's Phone",
                      keyboardType: TextInputType.phone,
                      validator: _required),
                  _field(_motherNameCtrl, "Mother's Name"),
                  _field(_motherPhoneCtrl, "Mother's Phone",
                      keyboardType: TextInputType.phone),
                  _field(_parentEmailCtrl, 'Parent Email',
                      keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Review & Submit'),
            isActive: _currentStep >= 3,
            content: _ReviewStep(
              name: _nameCtrl.text,
              dob: _dob != null
                  ? DateFormat('dd MMM yyyy').format(_dob!)
                  : '—',
              gender: _gender ?? '—',
              bloodGroup: _bloodGroup ?? '—',
              className: _className ?? '—',
              section: _sectionCtrl.text,
              rollNumber: _rollCtrl.text,
              admissionNumber: _admissionCtrl.text,
              fatherName: _fatherNameCtrl.text,
              fatherPhone: _fatherPhoneCtrl.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
        ),
      ),
    );
  }

  Widget _datePicker(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime(2010),
            firstDate: DateTime(1990),
            lastDate: DateTime.now(),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            suffixIcon: const Icon(Icons.calendar_today_rounded),
          ),
          child: Text(
            value != null
                ? DateFormat('dd MMM yyyy').format(value)
                : 'Select date',
            style: TextStyle(
              color: value != null
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> options,
    String? value,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    return Padding(
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
        validator: required ? (v) => v == null ? 'Required' : null : null,
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

// ── Review Step ───────────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.name,
    required this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.className,
    required this.section,
    required this.rollNumber,
    required this.admissionNumber,
    required this.fatherName,
    required this.fatherPhone,
  });

  final String name;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String className;
  final String section;
  final String rollNumber;
  final String admissionNumber;
  final String fatherName;
  final String fatherPhone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _ReviewSection(
          title: 'Personal',
          colorScheme: colorScheme,
          items: [
            _ReviewItem('Name', name),
            _ReviewItem('DOB', dob),
            _ReviewItem('Gender', gender),
            _ReviewItem('Blood Group', bloodGroup),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Academic',
          colorScheme: colorScheme,
          items: [
            _ReviewItem('Class', className),
            _ReviewItem('Section', section),
            _ReviewItem('Roll Number', rollNumber),
            _ReviewItem('Admission No.', admissionNumber),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Parent',
          colorScheme: colorScheme,
          items: [
            _ReviewItem('Father', fatherName),
            _ReviewItem('Father Phone', fatherPhone),
          ],
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.items,
    required this.colorScheme,
  });
  final String title;
  final List<_ReviewItem> items;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem(this.label, this.value);
  final String label;
  final String value;
}
