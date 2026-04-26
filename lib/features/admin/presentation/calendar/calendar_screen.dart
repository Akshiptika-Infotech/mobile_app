import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/confirmation_dialog.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/calendar_provider.dart';

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
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
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
  final _targetClassCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _type = 'general';
  bool _saving = false;

  static const _types = ['general', 'holiday', 'exam', 'event'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _targetClassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;
    setState(() => _selectedDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(calendarProvider.notifier).createEvent(
            title: _titleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            type: _type,
            date: _selectedDate,
            targetClass: _targetClassCtrl.text.trim(),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Event',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                  labelText: 'Description',
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
                items: _types
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetClassCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Class (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 16),
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
