import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:mobile_app/features/parent/presentation/widgets/child_selector.dart';

class ParentCalendarScreen extends ConsumerWidget {
  const ParentCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final month = ref.watch(calendarMonthProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Calendar'), centerTitle: false),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: ChildSelector(),
          ),
          _MonthSwitcher(
            month: month,
            onPrev: () {
              final prev = DateTime(month.year, month.month - 1);
              ref.read(calendarMonthProvider.notifier).state = prev;
            },
            onNext: () {
              final next = DateTime(month.year, month.month + 1);
              ref.read(calendarMonthProvider.notifier).state = next;
            },
          ),
          _MonthGrid(month: month, eventsAsync: eventsAsync),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      Text('$e', style: TextStyle(color: cs.error)),
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No events this month.',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: events.length,
                  itemBuilder: (_, i) => _EventCard(event: events[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy').format(month),
                style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.eventsAsync});
  final DateTime month;
  final AsyncValue<List<CalendarEvent>> eventsAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final leadingBlanks = (firstDay.weekday - 1) % 7; // Mon=0..Sun=6
    final totalCells =
        ((leadingBlanks + lastDay.day) / 7).ceil() * 7;

    // Index events per day-of-month for quick lookup.
    final eventDays = <int, List<CalendarEvent>>{};
    final events = eventsAsync.value ?? const <CalendarEvent>[];
    for (final e in events) {
      final d = DateTime.tryParse(e.date);
      if (d == null) continue;
      if (d.year == month.year && d.month == month.month) {
        eventDays.putIfAbsent(d.day, () => []).add(e);
      }
    }

    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        children: [
          Row(
            children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: totalCells,
            itemBuilder: (_, idx) {
              final day = idx - leadingBlanks + 1;
              if (day < 1 || day > lastDay.day) {
                return const SizedBox.shrink();
              }
              final cellDate = DateTime(month.year, month.month, day);
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final dayEvents = eventDays[day] ?? const [];
              return Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? cs.primary
                      : (dayEvents.isNotEmpty
                          ? cs.primaryContainer.withValues(alpha: 0.4)
                          : cs.surface),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isToday
                            ? Colors.white
                            : (dayEvents.isNotEmpty
                                ? cs.onPrimaryContainer
                                : cs.onSurface),
                        fontWeight: dayEvents.isNotEmpty
                            ? FontWeight.w800
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (dayEvents.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 2,
                          children: dayEvents.take(3).map((e) {
                            return Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isToday ? Colors.white : e.typeColor,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = DateTime.tryParse(event.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: event.typeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (d != null)
                  Text(DateFormat('EEEE, d MMM').format(d),
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                if (event.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: event.typeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              event.type.toUpperCase(),
              style: TextStyle(
                  color: event.typeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
