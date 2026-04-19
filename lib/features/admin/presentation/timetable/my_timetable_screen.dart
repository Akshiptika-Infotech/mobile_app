import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/features/admin/providers/timetable_provider.dart';

class MyTimetableScreen extends ConsumerStatefulWidget {
  const MyTimetableScreen({super.key});

  @override
  ConsumerState<MyTimetableScreen> createState() =>
      _MyTimetableScreenState();
}

class _MyTimetableScreenState extends ConsumerState<MyTimetableScreen>
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
    // Default to today's weekday tab (Mon=0 … Sat=5); clamp for Sunday.
    final todayIndex =
        (DateTime.now().weekday - 1).clamp(0, 5);
    _tabController =
        TabController(length: _days.length, vsync: this, initialIndex: todayIndex);
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
        title: const Text('My Timetable'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _days
              .map((d) => Tab(text: d.substring(0, 3)))
              .toList(),
        ),
      ),
      body: periodsAsync.when(
        loading: () => _TimetableSkeleton(tabController: _tabController),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(timetableProvider),
        ),
        data: (periods) => TabBarView(
          controller: _tabController,
          children: _days.map((day) {
            final dayPeriods = periods
                .where((p) => p.day.toLowerCase() == day.toLowerCase())
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
            return _DayView(day: day, periods: dayPeriods);
          }).toList(),
        ),
      ),
    );
  }
}

// ── Day view ──────────────────────────────────────────────────────────────────

class _DayView extends StatelessWidget {
  const _DayView({required this.day, required this.periods});
  final String day;
  final List<TimetablePeriod> periods;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No classes on $day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: periods.length,
      itemBuilder: (context, i) => _PeriodCard(
        period: periods[i],
        index: i,
      ),
    );
  }
}

// ── Period card ───────────────────────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Time column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          period.startTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(Icons.arrow_downward_rounded,
                            size: 12,
                            color: cs.onSurfaceVariant),
                        const SizedBox(height: 2),
                        Text(
                          period.endTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 48,
                      color:
                          cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 16),
                    // Subject & class info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period.subject,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.class_rounded,
                                  size: 13,
                                  color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${period.className} – ${period.section}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Period badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'P${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
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

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _TimetableSkeleton extends StatelessWidget {
  const _TimetableSkeleton({required this.tabController});
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: List.generate(
        6,
        (_) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: 5,
          itemBuilder: (_, i) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _Shimmer(height: 88, radius: 16),
          ),
        ),
      ),
    );
  }
}

// ── Shared shimmer ────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.height, this.radius = 8});
  final double height;
  final double radius;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.06, end: 0.16).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: _anim.value)
              : Colors.black.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: cs.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded,
                  size: 36, color: cs.onErrorContainer),
            ),
            const SizedBox(height: 16),
            Text('Failed to load timetable',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
