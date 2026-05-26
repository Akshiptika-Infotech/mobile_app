import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/parent/domain/student_attendance_model.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:mobile_app/features/parent/presentation/widgets/child_selector.dart';

class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final month = ref.watch(attendanceMonthProvider);
    final async = ref.watch(attendanceProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Attendance'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
          children: [
            const ChildSelector(),
            const SizedBox(height: 8),
            _MonthSwitcher(
              month: month,
              onPrev: () =>
                  ref.read(attendanceMonthProvider.notifier).state =
                      DateTime(month.year, month.month - 1),
              onNext: () =>
                  ref.read(attendanceMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1),
            ),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e', style: TextStyle(color: cs.error)),
              ),
              data: (data) {
                final daysByDate = <String, StudentAttendanceDay>{};
                for (final d in data.days) {
                  daysByDate[d.date] = d;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _SummaryCard(summary: data.summary),
                      const SizedBox(height: 12),
                      _AttendanceGrid(
                          month: month, daysByDate: daysByDate),
                      const SizedBox(height: 12),
                      _Legend(),
                      const SizedBox(height: 12),
                      _DayList(days: data.days),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Center(
              child: Text(DateFormat('MMMM yyyy').format(month),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final StudentAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attendance · this month',
                    style: TextStyle(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${summary.presentPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${summary.present} present · ${summary.absent} absent · ${summary.late} late · ${summary.leave} leave',
                  style: TextStyle(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                      fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.insights_rounded,
              color: cs.onPrimaryContainer, size: 36),
        ],
      ),
    );
  }
}

class _AttendanceGrid extends StatelessWidget {
  const _AttendanceGrid({required this.month, required this.daysByDate});
  final DateTime month;
  final Map<String, StudentAttendanceDay> daysByDate;

  String _key(int d) =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final leading = (firstDay.weekday - 1) % 7;
    final total = ((leading + lastDay.day) / 7).ceil() * 7;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: total,
            itemBuilder: (_, idx) {
              final day = idx - leading + 1;
              if (day < 1 || day > lastDay.day) {
                return const SizedBox.shrink();
              }
              final cellDate = DateTime(month.year, month.month, day);
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final att = daysByDate[_key(day)];
              final color = _colorFor(att?.status, cs);
              final fg = att == null
                  ? cs.onSurface
                  : (att.status == AttendanceStatus.holiday
                      ? cs.onSurfaceVariant
                      : Colors.white);
              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: cs.primary, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text('$day',
                    style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _colorFor(AttendanceStatus? s, ColorScheme cs) {
    switch (s) {
      case AttendanceStatus.present:
        return const Color(0xFF10B981);
      case AttendanceStatus.absent:
        return const Color(0xFFEF4444);
      case AttendanceStatus.late:
        return const Color(0xFFF59E0B);
      case AttendanceStatus.leave:
        return const Color(0xFF6366F1);
      case AttendanceStatus.holiday:
        return cs.surfaceContainerHigh;
      case AttendanceStatus.unmarked:
      case null:
        return cs.surfaceContainerLowest;
    }
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(Color c, String l) => Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(l,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        chip(const Color(0xFF10B981), 'Present'),
        chip(const Color(0xFFEF4444), 'Absent'),
        chip(const Color(0xFFF59E0B), 'Late'),
        chip(const Color(0xFF6366F1), 'Leave'),
      ],
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.days});
  final List<StudentAttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final marked = days
        .where((d) =>
            d.status != AttendanceStatus.unmarked &&
            d.status != AttendanceStatus.holiday)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (marked.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text('No marked days yet this month.',
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < marked.length; i++) ...[
            _DayRow(day: marked[i]),
            if (i < marked.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});
  final StudentAttendanceDay day;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (day.status) {
      AttendanceStatus.present => const Color(0xFF10B981),
      AttendanceStatus.absent => const Color(0xFFEF4444),
      AttendanceStatus.late => const Color(0xFFF59E0B),
      AttendanceStatus.leave => const Color(0xFF6366F1),
      _ => cs.onSurfaceVariant,
    };
    final d = DateTime.tryParse(day.date);
    final label =
        d == null ? day.date : DateFormat('EEE, d MMM').format(d);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(day.status.label.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4)),
          ),
        ],
      ),
    );
  }
}
