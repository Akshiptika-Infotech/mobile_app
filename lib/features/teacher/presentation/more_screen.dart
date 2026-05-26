import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/core/widgets/dashboard_avatar.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

class TeacherMoreScreen extends ConsumerWidget {
  const TeacherMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final config = AppConfigScope.of(context);
    final primary = config.primaryColor;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('More'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Profile header card ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary,
                  HSLColor.fromColor(primary)
                      .withLightness(
                          (HSLColor.fromColor(primary).lightness - 0.15)
                              .clamp(0.05, 1.0))
                      .toColor(),
                ],
              ),
            ),
            child: Row(
              children: [
                DashboardAvatar(
                  radius: 28,
                  imageUrl: user?.image,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  fallback: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Teacher',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'TEACHER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white),
                  onPressed: () => context.go('/teacher/profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Academic group ─────────────────────────────────────────────
          _GroupHeader(label: 'Academic', color: primary),
          _MenuTile(
            icon: Icons.calendar_view_week_rounded,
            label: 'Timetable',
            subtitle: 'Your weekly teaching schedule',
            color: const Color(0xFF6366F1),
            onTap: () => context.go('/teacher/timetable'),
          ),
          _MenuTile(
            icon: Icons.event_rounded,
            label: 'Calendar',
            subtitle: "Class & school events",
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/teacher/calendar'),
          ),
          _MenuTile(
            icon: Icons.insights_rounded,
            label: 'Report Cards',
            subtitle: 'Generate & review class reports',
            color: const Color(0xFFEC4899),
            onTap: () => context.go('/teacher/exams/report-cards'),
          ),

          const SizedBox(height: 18),
          _GroupHeader(label: 'Personal', color: primary),
          _MenuTile(
            icon: Icons.person_pin_circle_rounded,
            label: 'My Attendance',
            subtitle: 'Track your own attendance record',
            color: const Color(0xFF10B981),
            onTap: () => context.go('/teacher/my-attendance'),
          ),
          _MenuTile(
            icon: Icons.event_note_rounded,
            label: 'My Leaves',
            subtitle: 'Request leave & view status',
            color: const Color(0xFFF59E0B),
            onTap: () => context.go('/teacher/leaves'),
          ),
          _MenuTile(
            icon: Icons.account_circle_rounded,
            label: 'Profile',
            subtitle: 'Account settings & details',
            color: const Color(0xFF3B82F6),
            onTap: () => context.go('/teacher/profile'),
          ),

          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: Icon(Icons.logout_rounded, color: cs.error),
            label: Text('Sign out',
                style: TextStyle(
                    color: cs.error, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              config.appName,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
