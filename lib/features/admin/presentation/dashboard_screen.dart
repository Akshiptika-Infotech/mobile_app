import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/admin/domain/dashboard_model.dart';
import 'package:mobile_app/features/admin/providers/dashboard_provider.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.watch(currentUserProvider);
    final config = AppConfigScope.of(context);
    final primary = config.primaryColor;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    final primaryDark = HSLColor.fromColor(primary)
        .withLightness(
            (HSLColor.fromColor(primary).lightness - 0.15).clamp(0.05, 1.0))
        .toColor();

    // Responsive header height
    final expandedHeight = size.height < 600 ? 120.0 : 160.0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        color: primary,
        child: CustomScrollView(
          slivers: [
            // ── Gradient hero header ─────────────────────────────────────
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
                  icon: const Icon(Icons.logout_outlined, color: Colors.white),
                  tooltip: 'Sign out',
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, primaryDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    user?.name.isNotEmpty == true
                                        ? user!.name[0].toUpperCase()
                                        : 'A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${user?.name.split(' ').first ?? 'Admin'} 👋',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('EEEE, d MMMM yyyy')
                                          .format(DateTime.now()),
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    size: 8,
                                    color: Colors.greenAccent.shade400),
                                const SizedBox(width: 6),
                                Text(
                                  config.appName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: user?.role == AppRole.teacher
                  ? _TeacherDashboardContent(primary: primary)
                  : statsAsync.when(
                      loading: () => const _DashboardSkeleton(),
                      error: (error, _) => _ErrorState(
                        message: error.toString(),
                        onRetry: () =>
                            ref.refresh(dashboardStatsProvider.future),
                      ),
                      data: (stats) =>
                          _DashboardContent(stats: stats, primary: primary),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Teacher dashboard content ─────────────────────────────────────────────────

class _TeacherDashboardContent extends StatelessWidget {
  const _TeacherDashboardContent({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmalPhone = size.width < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: isSmalPhone
                    ? (size.width - 32) / 2 - 4
                    : (size.width - 48) / 4,
                child: _QuickAction(
                  icon: Icons.calendar_view_week_rounded,
                  label: 'Timetable',
                  color: const Color(0xFF3B82F6),
                  onTap: () => context.go('/admin/timetable/my'),
                ),
              ),
              SizedBox(
                width: isSmalPhone
                    ? (size.width - 32) / 2 - 4
                    : (size.width - 48) / 4,
                child: _QuickAction(
                  icon: Icons.fact_check_rounded,
                  label: 'Attendance',
                  color: const Color(0xFF10B981),
                  onTap: () => context.go('/admin/attendance/my-class'),
                ),
              ),
              SizedBox(
                width: isSmalPhone
                    ? (size.width - 32) / 2 - 4
                    : (size.width - 48) / 4,
                child: _QuickAction(
                  icon: Icons.assignment_rounded,
                  label: 'Marks',
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.go('/admin/exams/marks'),
                ),
              ),
              SizedBox(
                width: isSmalPhone
                    ? (size.width - 32) / 2 - 4
                    : (size.width - 48) / 4,
                child: _QuickAction(
                  icon: Icons.event_rounded,
                  label: 'Calendar',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.go('/admin/calendar'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
            title: 'Teacher Portal', icon: Icons.school_rounded),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _TeacherMenuTile(
                icon: Icons.people_outlined,
                label: 'My Class Students',
                subtitle: 'View your class roster',
                color: const Color(0xFF3B82F6),
                onTap: () => context.go('/admin/students/my-class'),
              ),
              const SizedBox(height: 10),
              _TeacherMenuTile(
                icon: Icons.person_outlined,
                label: 'My Attendance',
                subtitle: 'View your attendance record',
                color: const Color(0xFF10B981),
                onTap: () => context.go('/admin/attendance/my-attendance'),
              ),
              const SizedBox(height: 10),
              _TeacherMenuTile(
                icon: Icons.bar_chart_rounded,
                label: 'Report Cards',
                subtitle: 'View class report cards',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.go('/admin/exams/report-cards'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _TeacherMenuTile extends StatelessWidget {
  const _TeacherMenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard content ─────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats, required this.primary});
  final DashboardStats stats;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final fmtCurrency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final fmtInt = NumberFormat('#,##,##0', 'en_IN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Quick actions ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmalPhone = constraints.maxWidth < 340;
              final itemWidth = isSmalPhone
                  ? (constraints.maxWidth) / 2 - 4
                  : (constraints.maxWidth) / 4;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.task_alt_rounded,
                      label: 'Approvals',
                      color: const Color(0xFFEA580C),
                      onTap: () => context.go('/admin/approvals'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.go('/admin/reports/collection'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.group_rounded,
                      label: 'Users',
                      color: const Color(0xFF2563EB),
                      onTap: () => context.go('/admin/users'),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      color: const Color(0xFF16A34A),
                      onTap: () => context.go('/admin/profile'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // ── KPI section header ─────────────────────────────────────────
        const _SectionHeader(title: "Today's Overview", icon: Icons.insights_rounded),
        const SizedBox(height: 12),

        // ── KPI 2×2 grid ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
            ),
            children: [
              _KpiCard(
                label: "Today's Collection",
                value: fmtCurrency.format(stats.todayCollection),
                icon: Icons.today_rounded,
                color: const Color(0xFF10B981),
                subLabel: 'collected today',
              ),
              _KpiCard(
                label: 'Monthly Total',
                value: fmtCurrency.format(stats.monthlyTotal),
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF3B82F6),
                subLabel: 'this month',
              ),
              _KpiCard(
                label: 'Active Students',
                value: fmtInt.format(stats.activeStudents),
                icon: Icons.school_rounded,
                color: const Color(0xFFF59E0B),
                subLabel: 'enrolled',
              ),
              _KpiCard(
                label: 'Staff',
                value: fmtInt.format(stats.staffCount),
                icon: Icons.badge_rounded,
                color: const Color(0xFF8B5CF6),
                subLabel: 'total staff',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Defaulters ─────────────────────────────────────────────────
        const _SectionHeader(
            title: 'Top Defaulters', icon: Icons.warning_amber_rounded),
        const SizedBox(height: 12),

        if (stats.topDefaulters.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded,
                        size: 36, color: Colors.green.shade600),
                  ),
                  const SizedBox(height: 12),
                  Text('No outstanding dues',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: stats.topDefaulters
                  .map((d) =>
                      _DefaulterCard(defaulter: d, fmt: fmtCurrency))
                  .toList(),
            ),
          ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Quick action button ───────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subLabel,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(Icons.trending_up_rounded,
                    size: 16,
                    color: color.withValues(alpha: 0.6)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Defaulter card ────────────────────────────────────────────────────────────

class _DefaulterCard extends StatelessWidget {
  const _DefaulterCard({required this.defaulter, required this.fmt});
  final Defaulter defaulter;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cs.errorContainer,
          backgroundImage: defaulter.photo != null
              ? NetworkImage(defaulter.photo!)
              : null,
          onBackgroundImageError: defaulter.photo != null
              ? (_, __) {}
              : null,
          child: defaulter.photo == null
              ? Text(
                  defaulter.name.isNotEmpty
                      ? defaulter.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(defaulter.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(defaulter.classDisplay,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            fmt.format(defaulter.amountDue),
            style: TextStyle(
              color: cs.onErrorContainer,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: List.generate(
                4,
                (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
                        child: const _Shimmer(height: 72, radius: 14),
                      ),
                    )),
          ),
          const SizedBox(height: 24),
          const _Shimmer(height: 18, width: 140),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
                4, (_) => const _Shimmer(height: 100, radius: 18)),
          ),
          const SizedBox(height: 24),
          const _Shimmer(height: 18, width: 140),
          const SizedBox(height: 12),
          ...List.generate(
              3,
              (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _Shimmer(height: 64, radius: 14),
                  )),
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer(
      {required this.height, this.width = double.infinity, this.radius = 8});
  final double height;
  final double width;
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
    _anim = Tween<double>(begin: 0.08, end: 0.18).animate(
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
        width: widget.width,
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded,
                size: 36, color: cs.onErrorContainer),
          ),
          const SizedBox(height: 16),
          Text('Failed to load dashboard',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
