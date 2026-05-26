import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/core/widgets/dashboard_avatar.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/features/admin/providers/attendance_provider.dart';
import 'package:mobile_app/features/admin/providers/timetable_provider.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

/// Greeting that adapts to the time of day.
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final config = AppConfigScope.of(context);
    final primary = config.primaryColor;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    final primaryDark = HSLColor.fromColor(primary)
        .withLightness(
            (HSLColor.fromColor(primary).lightness - 0.18).clamp(0.05, 1.0))
        .toColor();

    final expandedHeight = size.height < 600 ? 200.0 : 240.0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        color: primary,
        onRefresh: () async {
          ref.invalidate(myClassAttendanceProvider);
          ref.invalidate(timetableProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: expandedHeight,
              pinned: true,
              backgroundColor: primary,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  tooltip: 'Notifications',
                  onPressed: () {},
                ),
                IconButton(
                  icon:
                      const Icon(Icons.logout_outlined, color: Colors.white),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, primaryDark],
                        ),
                      ),
                    ),
                    // Decorative circles for visual interest.
                    Positioned(
                      top: -40,
                      right: -30,
                      child: _Bubble(
                          size: 140,
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -20,
                      child: _Bubble(
                          size: 160,
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                DashboardAvatar(
                                  radius: 24,
                                  imageUrl: user?.image,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.22),
                                  onTap: () =>
                                      context.go('/teacher/profile'),
                                  fallback: Text(
                                    user?.name.isNotEmpty == true
                                        ? user!.name[0].toUpperCase()
                                        : 'T',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_greeting()},',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        user?.name.split(' ').first ??
                                            'Teacher',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEEE, d MMMM yyyy')
                                        .format(DateTime.now()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TodaySnapshot(),
                    const SizedBox(height: 22),
                    _SectionTitle(
                        title: 'Quick actions',
                        icon: Icons.flash_on_rounded,
                        accent: primary),
                    const SizedBox(height: 12),
                    const _QuickActionGrid(),
                    const SizedBox(height: 24),
                    _SectionTitle(
                        title: "Today's schedule",
                        icon: Icons.schedule_rounded,
                        accent: primary),
                    const SizedBox(height: 12),
                    const _TodayScheduleCard(),
                    const SizedBox(height: 24),
                    _SectionTitle(
                        title: 'Teaching hub',
                        icon: Icons.auto_awesome_rounded,
                        accent: primary),
                    const SizedBox(height: 12),
                    const _TeachingHubGrid(),
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

// ── Today snapshot (class attendance counts) ──────────────────────────────────

class _TodaySnapshot extends ConsumerWidget {
  const _TodaySnapshot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myClassAttendanceProvider);
    final cs = Theme.of(context).colorScheme;
    final primary = AppConfigScope.of(context).primaryColor;

    int present = 0, absent = 0, leave = 0;
    for (final s in state.students) {
      switch (s.status.toLowerCase()) {
        case 'present':
          present++;
        case 'absent':
          absent++;
        case 'leave':
        case 'medical':
          leave++;
      }
    }
    final total = state.students.length;
    final percent = total == 0 ? 0.0 : present / total;
    final isLoading = state.isLoading && state.students.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fact_check_rounded,
                    color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's class",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      total == 0
                          ? 'No roster loaded yet'
                          : '$total students • ${(percent * 100).round()}% present',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/teacher/attendance'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 6)
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(primary),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Present',
                  count: present,
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Absent',
                  count: absent,
                  color: const Color(0xFFEF4444),
                  icon: Icons.cancel_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Leave',
                  count: leave,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.event_busy_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action grid ─────────────────────────────────────────────────────────

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _QuickAction(
        icon: Icons.qr_code_scanner_rounded,
        label: 'QR Attendance',
        color: Color(0xFF6366F1),
        route: '/teacher/attendance/qr-setup',
      ),
      _QuickAction(
        icon: Icons.edit_calendar_rounded,
        label: 'Mark Attendance',
        color: Color(0xFF10B981),
        route: '/teacher/attendance',
      ),
      _QuickAction(
        icon: Icons.assignment_turned_in_rounded,
        label: 'Marks Entry',
        color: Color(0xFFF59E0B),
        route: '/teacher/exams/marks',
      ),
      _QuickAction(
        icon: Icons.event_rounded,
        label: 'Calendar',
        color: Color(0xFF8B5CF6),
        route: '/teacher/calendar',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 12) / 4;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: items.map((a) => SizedBox(width: w, child: a)).toList(),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today schedule card ───────────────────────────────────────────────────────

const _weekdayNames = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

class _TodayScheduleCard extends ConsumerWidget {
  const _TodayScheduleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timetableProvider);
    final cs = Theme.of(context).colorScheme;
    final primary = AppConfigScope.of(context).primaryColor;

    final todayName = _weekdayNames[DateTime.now().weekday - 1];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: cs.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Could not load timetable',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(timetableProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (periods) {
          final todays = periods
              .where((p) => p.day.toUpperCase() == todayName)
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          if (todays.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded,
                      color: primary.withValues(alpha: 0.6), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'No classes scheduled today',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enjoy your day!',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              for (var i = 0; i < todays.length; i++) ...[
                _PeriodTile(period: todays[i]),
                if (i < todays.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
              ],
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.period});
  final TimetablePeriod period;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = AppConfigScope.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  period.startTime,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: primary,
                  ),
                ),
                Container(
                  height: 1,
                  width: 16,
                  color: primary.withValues(alpha: 0.4),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                Text(
                  period.endTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.subject.isEmpty ? 'Subject' : period.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (period.className.isNotEmpty) period.className,
                    if (period.section.isNotEmpty) period.section,
                  ].join(' • '),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

// ── Teaching hub grid ─────────────────────────────────────────────────────────

class _TeachingHubGrid extends StatelessWidget {
  const _TeachingHubGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: const [
        _HubCard(
          icon: Icons.groups_rounded,
          label: 'My Class',
          subtitle: 'Roster & details',
          color: Color(0xFF3B82F6),
          route: '/teacher/class',
        ),
        _HubCard(
          icon: Icons.calendar_view_week_rounded,
          label: 'Timetable',
          subtitle: 'Weekly schedule',
          color: Color(0xFF6366F1),
          route: '/teacher/timetable',
        ),
        _HubCard(
          icon: Icons.insights_rounded,
          label: 'Report Cards',
          subtitle: 'Class results',
          color: Color(0xFF8B5CF6),
          route: '/teacher/exams/report-cards',
        ),
        _HubCard(
          icon: Icons.event_note_rounded,
          label: 'My Leaves',
          subtitle: 'Request & track',
          color: Color(0xFFEC4899),
          route: '/teacher/leaves',
        ),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.accent,
  });
  final String title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ── Decorative bubble ─────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

