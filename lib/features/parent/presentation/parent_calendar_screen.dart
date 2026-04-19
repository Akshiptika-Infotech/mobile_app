import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/features/parent/providers/parent_provider.dart';

// Tracks current month/year + selected day locally
class _CalendarViewState {
  const _CalendarViewState({
    required this.year,
    required this.month,
    this.selectedDay,
  });
  final int year;
  final int month;
  final int? selectedDay;

  _CalendarViewState copyWith({int? year, int? month, int? selectedDay,
      bool clearDay = false}) {
    return _CalendarViewState(
      year: year ?? this.year,
      month: month ?? this.month,
      selectedDay: clearDay ? null : selectedDay ?? this.selectedDay,
    );
  }
}

class ParentCalendarScreen extends ConsumerStatefulWidget {
  const ParentCalendarScreen({super.key});

  @override
  ConsumerState<ParentCalendarScreen> createState() =>
      _ParentCalendarScreenState();
}

class _ParentCalendarScreenState extends ConsumerState<ParentCalendarScreen> {
  late _CalendarViewState _view;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _view = _CalendarViewState(
        year: now.year, month: now.month, selectedDay: now.day);
  }

  void _prevMonth() {
    final d = DateTime(_view.year, _view.month - 1);
    setState(() =>
        _view = _view.copyWith(year: d.year, month: d.month, clearDay: true));
  }

  void _nextMonth() {
    final d = DateTime(_view.year, _view.month + 1);
    setState(() =>
        _view = _view.copyWith(year: d.year, month: d.month, clearDay: true));
  }

  List<CalendarEvent> _eventsForDay(List<CalendarEvent> all, int day) {
    final target =
        '${_view.year.toString().padLeft(4, '0')}-${_view.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    return all.where((e) => e.date.startsWith(target)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final childrenAsync = ref.watch(parentChildrenProvider);

    // Resolve the effective studentId
    final effectiveChildId = _selectedChildId ??
        childrenAsync.valueOrNull?.firstOrNull?.id;

    final params = effectiveChildId != null
        ? (studentId: effectiveChildId, month: _view.month, year: _view.year)
        : null;

    final eventsAsync = params != null
        ? ref.watch(parentCalendarProvider(params))
        : const AsyncValue<List<CalendarEvent>>.loading();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (params != null) ref.invalidate(parentCalendarProvider(params));
            },
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (params != null) ref.invalidate(parentCalendarProvider(params));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (events) => CustomScrollView(
          slivers: [
            // ── Month header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _MonthHeader(
                year: _view.year,
                month: _view.month,
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
            ),
            // ── Weekday labels ────────────────────────────────────────────
            SliverToBoxAdapter(child: _WeekdayRow()),
            // ── Day grid ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _CalendarGrid(
                year: _view.year,
                month: _view.month,
                selectedDay: _view.selectedDay,
                eventDays: events
                    .map((e) => e.date.length >= 10
                        ? int.tryParse(e.date.substring(8, 10))
                        : null)
                    .whereType<int>()
                    .toSet(),
                onDayTap: (d) =>
                    setState(() => _view = _view.copyWith(selectedDay: d)),
              ),
            ),
            SliverToBoxAdapter(
                child: Divider(height: 1, color: cs.outlineVariant)),
            // ── Events for selected day ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  _view.selectedDay != null
                      ? DateFormat('EEEE, d MMMM').format(
                          DateTime(_view.year, _view.month, _view.selectedDay!))
                      : DateFormat('MMMM yyyy')
                          .format(DateTime(_view.year, _view.month)),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ..._buildEventSliver(context, cs,
                _view.selectedDay != null
                    ? _eventsForDay(events, _view.selectedDay!)
                    : events),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventSliver(
      BuildContext context, ColorScheme cs, List<CalendarEvent> dayEvents) {
    if (dayEvents.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(children: [
                Icon(Icons.event_busy_rounded,
                    size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 10),
                Text('No events',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ]),
            ),
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _EventTile(event: dayEvents[i]),
          ),
          childCount: dayEvents.length,
        ),
      ),
    ];
  }
}

// ── Month header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = DateFormat('MMMM yyyy').format(DateTime(year, month));
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left_rounded), onPressed: onPrev),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Weekday row ───────────────────────────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.eventDays,
    required this.onDayTap,
  });
  final int year;
  final int month;
  final int? selectedDay;
  final Set<int> eventDays;
  final ValueChanged<int> onDayTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firstDay = DateTime(year, month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    final cells = <Widget>[];
    for (var i = 0; i < startOffset; i++) { cells.add(const SizedBox()); }
    for (var d = 1; d <= daysInMonth; d++) {
      final isSelected = selectedDay == d;
      final isToday =
          year == today.year && month == today.month && d == today.day;
      final hasEvent = eventDays.contains(d);

      cells.add(GestureDetector(
        onTap: () => onDayTap(d),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary
                : isToday
                    ? cs.primaryContainer
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(alignment: Alignment.center, children: [
            Text('$d',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? cs.onPrimary
                      : isToday
                          ? cs.onPrimaryContainer
                          : cs.onSurface,
                )),
            if (hasEvent)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? cs.onPrimary : cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ]),
        ),
      ));
    }

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }
}

// ── Event tile ────────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = event.typeColor;
    final dateLabel = event.date.length >= 10
        ? DateFormat('d MMM')
            .format(DateTime.parse(event.date.substring(0, 10)))
        : event.date;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(event.description,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (event.targetClass != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.school_outlined,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(event.targetClass!,
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ]),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(event.type.toLowerCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
          const SizedBox(height: 4),
          Text(dateLabel,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}
