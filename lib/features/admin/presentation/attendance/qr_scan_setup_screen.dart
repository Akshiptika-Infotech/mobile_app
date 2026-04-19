import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/attendance_model.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';
import 'package:mobile_app/features/admin/providers/class_provider.dart';

class QrScanSetupScreen extends ConsumerStatefulWidget {
  const QrScanSetupScreen({super.key});

  @override
  ConsumerState<QrScanSetupScreen> createState() => _QrScanSetupScreenState();
}

class _QrScanSetupScreenState extends ConsumerState<QrScanSetupScreen> {
  AcademicYear? _selectedYear;
  SchoolClass? _selectedClass;
  Section? _selectedSection;
  DateTime _date = DateTime.now();

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  List<Section> _sectionsForClass(List<Section> all) =>
      all.where((s) => s.classId == _selectedClass?.id).toList();

  bool get _canStart =>
      _selectedYear != null && _selectedClass != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _startScan() {
    if (!_canStart) return;
    final params = QrScanParams(
      classId: _selectedClass!.id,
      className: _selectedClass!.name,
      academicYearId: _selectedYear!.id,
      date: _dateStr,
      sectionId: _selectedSection?.id,
      sectionName: _selectedSection?.name,
    );
    context.push('/admin/attendance/qr-scan', extra: params);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final yearsAsync = ref.watch(academicYearsProvider);
    final classesAsync = ref.watch(classesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('QR Attendance Setup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    color: cs.primary, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QR Code Attendance',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: cs.primary)),
                      Text('Scan student ID cards to mark attendance',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Academic Year
          const _SectionLabel(label: 'Academic Year'),
          const SizedBox(height: 8),
          yearsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e',
                style: TextStyle(color: cs.error)),
            data: (years) {
              if (_selectedYear == null && years.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedYear =
                      years.firstWhere((y) => y.isActive,
                          orElse: () => years.first));
                });
              }
              return _DropdownCard<AcademicYear>(
                value: _selectedYear,
                items: years,
                labelBuilder: (y) => y?.name ?? '',
                hint: 'Select academic year',
                onChanged: (y) => setState(() => _selectedYear = y),
              );
            },
          ),
          const SizedBox(height: 16),

          // Class
          const _SectionLabel(label: 'Class'),
          const SizedBox(height: 8),
          classesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e',
                style: TextStyle(color: cs.error)),
            data: (classes) => _DropdownCard<SchoolClass>(
              value: _selectedClass,
              items: classes,
              labelBuilder: (c) => c?.name ?? '',
              hint: 'Select class',
              onChanged: (c) => setState(() {
                _selectedClass = c;
                _selectedSection = null;
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Section (optional)
          const _SectionLabel(label: 'Section (optional)'),
          const SizedBox(height: 8),
          sectionsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (allSections) {
              final sections = _sectionsForClass(allSections);
              if (sections.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('No sections for this class',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13)),
                );
              }
              return _DropdownCard<Section>(
                value: _selectedSection,
                items: [null, ...sections.cast<Section?>()],
                labelBuilder: (s) => s?.name ?? 'All sections',
                hint: 'All sections',
                onChanged: (s) => setState(() => _selectedSection = s),
              );
            },
          ),
          const SizedBox(height: 16),

          // Date
          const _SectionLabel(label: 'Date'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: cs.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(_date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_rounded, size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Start button
          FilledButton.icon(
            onPressed: _canStart ? _startScan : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Start Scanning',
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  const _DropdownCard({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.hint,
    required this.onChanged,
  });

  final T? value;
  final List<T?> items;
  final String Function(T? item) labelBuilder;
  final String hint;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          hint: Text(hint,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          isExpanded: true,
          onChanged: onChanged,
          items: items
              .map((item) => DropdownMenuItem<T?>(
                    value: item,
                    child: Text(labelBuilder(item),
                        style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
