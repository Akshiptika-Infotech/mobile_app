import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:mobile_app/features/parent/presentation/widgets/child_selector.dart';

class ParentTimetableScreen extends ConsumerStatefulWidget {
  const ParentTimetableScreen({super.key});

  @override
  ConsumerState<ParentTimetableScreen> createState() =>
      _ParentTimetableScreenState();
}

class _ParentTimetableScreenState extends ConsumerState<ParentTimetableScreen>
    with SingleTickerProviderStateMixin {
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final wd = DateTime.now().weekday;
    final todayIndex =
        wd == DateTime.sunday ? 0 : (wd - 1).clamp(0, _days.length - 1);
    _tabController = TabController(
        length: _days.length, vsync: this, initialIndex: todayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final periodsAsync = ref.watch(timetableProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Timetable'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _days.map((d) => Tab(text: d.substring(0, 3))).toList(),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: ChildSelector(),
          ),
          Expanded(
            child: periodsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      Text('$e', style: TextStyle(color: cs.error)),
                ),
              ),
              data: (periods) {
                return TabBarView(
                  controller: _tabController,
                  children: _days.map((day) {
                    final dayPeriods = periods
                        .where((p) =>
                            p.day.toLowerCase() == day.toLowerCase())
                        .toList()
                      ..sort(
                          (a, b) => a.startTime.compareTo(b.startTime));
                    return _DayView(day: day, periods: dayPeriods);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  const _DayView({required this.day, required this.periods});
  final String day;
  final List<TimetablePeriod> periods;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (periods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_rounded,
                  size: 56,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('No classes on $day',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: periods.length,
      itemBuilder: (_, i) =>
          _PeriodCard(period: periods[i], index: i),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, required this.index});
  final TimetablePeriod period;
  final int index;

  static const _accentColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _accentColors[index % _accentColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(period.startTime,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accent)),
                        const SizedBox(height: 2),
                        Icon(Icons.arrow_downward_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(height: 2),
                        Text(period.endTime,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 1,
                      height: 44,
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(period.subject,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          if (period.teacherName.isNotEmpty)
                            Text(period.teacherName,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('P${index + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accent)),
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
