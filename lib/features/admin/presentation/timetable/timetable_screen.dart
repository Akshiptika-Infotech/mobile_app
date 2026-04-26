import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/data/timetable_repository.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/timetable_provider.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static const _dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String? _selectedClass;
  String? _selectedSection;

  void _setDefaultSelection(List<String> comboList) {
    if (_selectedClass != null || comboList.isEmpty) return;
    final parts = comboList.first.split('-');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedClass = parts[0];
        _selectedSection = parts.length > 1 ? parts[1] : '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final periodsAsync = ref.watch(adminTimetableProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Timetable'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminTimetableProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: periodsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 6),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminTimetableProvider),
        ),
        data: (periods) {
          // Gather distinct class+section combos
          final combos = <String>{};
          for (final p in periods) {
            combos.add('${p.className}-${p.section}');
          }
          final comboList = combos.toList()..sort();

          // Set default selection after build completes (never mutate state inside build).
          _setDefaultSelection(comboList);

          final filtered = periods.where((p) {
            return p.className == _selectedClass && p.section == (_selectedSection ?? '');
          }).toList();

          // Gather unique time slots sorted by start time
          final timeSlots = filtered.map((p) => '${p.startTime}-${p.endTime}').toSet().toList()
            ..sort();

          return Column(
            children: [
              // Class selector bar
              if (comboList.isNotEmpty)
                Container(
                  color: cs.surface,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: comboList.map((combo) {
                        final parts = combo.split('-');
                        final cls = parts[0];
                        final sec = parts.length > 1 ? parts[1] : '';
                        final selected = cls == _selectedClass && sec == _selectedSection;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(combo),
                            selected: selected,
                            onSelected: (_) => setState(() {
                              _selectedClass = cls;
                              _selectedSection = sec;
                            }),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (periods.isEmpty)
                const Expanded(
                  child: AppEmptyState(
                    message: 'No periods found. Tap + to add.',
                    icon: Icons.schedule_outlined,
                  ),
                )
              else if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No periods for this class',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                )
              else
                Expanded(
                  child: _WeeklyGrid(
                    periods: filtered,
                    days: _days,
                    dayAbbr: _dayAbbr,
                    timeSlots: timeSlots,
                    onEdit: (period) => _showEditSheet(context, period),
                    onDelete: (id) => _delete(id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(String id) async {
    try {
      await ref.read(timetableRepositoryProvider).deletePeriod(id);
      ref.invalidate(adminTimetableProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    }
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PeriodFormSheet(
        onSave: (data) async {
          await ref.read(timetableRepositoryProvider).createPeriod(data);
          ref.invalidate(adminTimetableProvider);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, TimetablePeriod period) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PeriodFormSheet(
        initial: period,
        onSave: (data) async {
          // Update by delete + create since API may not have a PUT
          await ref.read(timetableRepositoryProvider).deletePeriod(period.id);
          await ref.read(timetableRepositoryProvider).createPeriod(data);
          ref.invalidate(adminTimetableProvider);
        },
      ),
    );
  }
}

// ── Weekly grid ───────────────────────────────────────────────────────────────

class _WeeklyGrid extends StatelessWidget {
  const _WeeklyGrid({
    required this.periods,
    required this.days,
    required this.dayAbbr,
    required this.timeSlots,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TimetablePeriod> periods;
  final List<String> days;
  final List<String> dayAbbr;
  final List<String> timeSlots;
  final void Function(TimetablePeriod) onEdit;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Build lookup: day -> timeSlot -> period
    final Map<String, Map<String, TimetablePeriod>> lookup = {};
    for (final p in periods) {
      final slot = '${p.startTime}-${p.endTime}';
      lookup.putIfAbsent(p.day, () => {})[slot] = p;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Table(
            border: TableBorder.all(color: cs.outlineVariant, width: 0.5),
            defaultColumnWidth: const FixedColumnWidth(110),
            columnWidths: const {0: FixedColumnWidth(80)},
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: cs.surfaceContainerHigh),
                children: [
                  const _HeaderCell(text: 'Time'),
                  ...days.asMap().entries.map((e) => _HeaderCell(text: dayAbbr[e.key])),
                ],
              ),
              // Period rows
              ...timeSlots.map((slot) {
                final parts = slot.split('-');
                final start = parts[0];
                final end = parts.length > 1 ? parts[1] : '';
                return TableRow(
                  children: [
                    _TimeCell(start: start, end: end),
                    ...days.map((day) {
                      final period = lookup[day]?[slot];
                      if (period == null) {
                        return const _EmptyCell();
                      }
                      return _PeriodCell(
                        period: period,
                        onEdit: () => onEdit(period),
                        onDelete: () => onDelete(period.id),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.start, required this.end});
  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(start, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          Text(end, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 56);
  }
}

class _PeriodCell extends StatelessWidget {
  const _PeriodCell({required this.period, required this.onEdit, required this.onDelete});
  final TimetablePeriod period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onEdit,
      onLongPress: () async {
        final del = await ConfirmationDialog.show(
          context,
          title: 'Delete Period',
          message: 'Delete "${period.subject}"?',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (del) onDelete();
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period.subject,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              period.teacherName,
              style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period form sheet ─────────────────────────────────────────────────────────

class _PeriodFormSheet extends StatefulWidget {
  const _PeriodFormSheet({this.initial, required this.onSave});
  final TimetablePeriod? initial;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_PeriodFormSheet> createState() => _PeriodFormSheetState();
}

class _PeriodFormSheetState extends State<_PeriodFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _teacherCtrl;
  late final TextEditingController _classCtrl;
  late final TextEditingController _sectionCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  String _day = 'Monday';
  bool _saving = false;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _subjectCtrl = TextEditingController(text: p?.subject ?? '');
    _teacherCtrl = TextEditingController(text: p?.teacherName ?? '');
    _classCtrl = TextEditingController(text: p?.className ?? '');
    _sectionCtrl = TextEditingController(text: p?.section ?? '');
    _startCtrl = TextEditingController(text: p?.startTime ?? '');
    _endCtrl = TextEditingController(text: p?.endTime ?? '');
    _day = p?.day ?? 'Monday';
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _teacherCtrl.dispose();
    _classCtrl.dispose();
    _sectionCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'subject': _subjectCtrl.text.trim(),
        'teacherName': _teacherCtrl.text.trim(),
        'class': _classCtrl.text.trim(),
        'section': _sectionCtrl.text.trim(),
        'day': _day,
        'startTime': _startCtrl.text.trim(),
        'endTime': _endCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Add Period' : 'Edit Period',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _teacherCtrl,
                decoration: const InputDecoration(labelText: 'Teacher Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _classCtrl,
                      decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sectionCtrl,
                      decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _day,
                decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
                items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _day = v ?? _day),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startCtrl,
                      decoration: const InputDecoration(labelText: 'Start Time (HH:mm)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _endCtrl,
                      decoration: const InputDecoration(labelText: 'End Time (HH:mm)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.initial == null ? 'Add Period' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

