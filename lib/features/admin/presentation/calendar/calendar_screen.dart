import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';
import 'package:mobile_app/features/admin/providers/calendar_provider.dart';
import 'package:mobile_app/features/admin/providers/class_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: notifier.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
      body: Column(
        children: [
          _MonthHeader(state: state, notifier: notifier),
          _WeekdayRow(),
          _CalendarGrid(state: state, notifier: notifier),
          const Divider(height: 1),
          Expanded(child: _EventsList(state: state)),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateEventSheet(),
    );
  }
}

class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet();

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _type = 'EVENT';

  /// `null` → school-wide event (no class scope).
  SchoolClass? _selectedClass;

  /// `null` → all sections of the selected class. Ignored when no class
  /// is selected.
  Section? _selectedSection;

  bool _saving = false;

  /// Server's `EventType` enum — kept uppercase to match the backend.
  static const _types = <String, String>{
    'EVENT': 'Event',
    'HOLIDAY': 'Holiday',
    'EXAM': 'Exam',
    'ACTIVITY': 'Activity',
    'MEETING': 'Meeting',
    'OTHER': 'Other',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Auto-snap end date forward if it now precedes start.
        if (_endDate.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(calendarProvider.notifier).createEvent(
            title: _titleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            type: _type,
            startDate: _startDate,
            endDate: _endDate,
            classId: _selectedClass?.id,
            // sectionId only matters when classId is set — the backend
            // ignores it otherwise.
            sectionId:
                _selectedClass == null ? null : _selectedSection?.id,
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Event',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: _types.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerTile(
                      label: 'Start date',
                      date: _startDate,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerTile(
                      label: 'End date',
                      date: _endDate,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Class dropdown ─────────────────────────────────────
              classesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load classes: $e',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                data: (classes) => DropdownButtonFormField<SchoolClass?>(
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class (optional)',
                    helperText: 'Leave empty for a school-wide event',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<SchoolClass?>(
                      value: null,
                      child: Text('Whole school'),
                    ),
                    ...classes.map(
                      (c) => DropdownMenuItem<SchoolClass?>(
                        value: c,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (c) => setState(() {
                    _selectedClass = c;
                    // Reset section when class changes.
                    _selectedSection = null;
                  }),
                ),
              ),

              // ── Section dropdown (only when a class is picked) ────
              if (_selectedClass != null) ...[
                const SizedBox(height: 12),
                sectionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load sections: $e',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  data: (allSections) {
                    final sections = allSections
                        .where((s) => s.classId == _selectedClass!.id)
                        .toList();
                    return DropdownButtonFormField<Section?>(
                      initialValue: _selectedSection,
                      decoration: InputDecoration(
                        labelText: 'Section (optional)',
                        helperText: sections.isEmpty
                            ? 'No sections configured for this class'
                            : 'Leave empty for all sections of this class',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<Section?>(
                          value: null,
                          child: Text('All sections'),
                        ),
                        ...sections.map(
                          (s) => DropdownMenuItem<Section?>(
                            value: s,
                            child: Text(s.name),
                          ),
                        ),
                      ],
                      onChanged: (s) =>
                          setState(() => _selectedSection = s),
                    );
                  },
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
  });
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon:
              Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
        ),
        child: Text(DateFormat('dd MMM yyyy').format(date)),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.state, required this.notifier});
  final CalendarState state;
  final CalendarNotifier notifier;

  static const _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous month',
            onPressed: notifier.previousMonth,
          ),
          Expanded(
            child: Text(
              '${_monthNames[state.month]} ${state.year}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next month',
            onPressed: notifier.nextMonth,
          ),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: _days.map((d) {
          return Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: d == 'Sun' ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.state, required this.notifier});
  final CalendarState state;
  final CalendarNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firstDay = DateTime(state.year, state.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(state.year, state.month);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();
    final isCurrentMonth = today.year == state.year && today.month == state.month;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - startOffset + 1;
              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final isToday = isCurrentMonth && day == today.day;
              final isSelected = state.selectedDay == day;
              final events = state.eventsForDay(day);
              final isSunday = col == 6;

              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.selectDay(day),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : isToday
                              ? cs.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? cs.onPrimary
                                : isToday
                                    ? cs.onPrimaryContainer
                                    : isSunday
                                        ? cs.error
                                        : cs.onSurface,
                          ),
                        ),
                        if (events.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: events
                                .take(3)
                                .map(
                                  (e) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? cs.onPrimary.withValues(alpha: 0.8)
                                          : e.typeColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList({required this.state});
  final CalendarState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final events = state.selectedDayEvents;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: TextStyle(color: cs.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.selectedDay == null) {
      return Center(
        child: Text(
          'Tap a day to see events',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 40,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No events on day ${state.selectedDay}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: events.length,
      itemBuilder: (context, i) => _EventTile(event: events[i]),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final color = event.typeColor;
    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (event.targetClass != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.class_rounded, size: 11, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          event.targetClass!,
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event.type[0].toUpperCase() + event.type.substring(1),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await ConfirmationDialog.show(
      context,
      title: 'Delete Event',
      message: 'Delete "${event.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (shouldDelete != true) return;
    try {
      await ref.read(calendarProvider.notifier).deleteEvent(event.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event deleted')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    }
  }
}
