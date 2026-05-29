import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/admin/providers/my_profile_provider.dart';

class TeacherExamsHubScreen extends ConsumerWidget {
  const TeacherExamsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final primary = AppConfigScope.of(context).primaryColor;
    final profileAsync = ref.watch(myProfileProvider);
    final isMotherTeacher = profileAsync.value?.isMotherTeacher ?? false;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Exams'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your exams',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter marks, generate report cards, and review class results.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _BigActionCard(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Marks Entry',
              subtitle:
                  'Record subject-wise marks for students after each exam.',
              color: const Color(0xFFF59E0B),
              accent: primary,
              onTap: () => context.go('/teacher/exams/marks'),
            ),
            const SizedBox(height: 14),
            _BigActionCard(
              icon: Icons.insights_rounded,
              title: 'Report Cards',
              subtitle:
                  'Generate, view and share consolidated class report cards.',
              color: const Color(0xFF8B5CF6),
              accent: primary,
              onTap: () => context.go('/teacher/exams/report-cards'),
            ),
            if (isMotherTeacher) ...[
              const SizedBox(height: 14),
              _BigActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Manage Subjects',
                subtitle: 'Add, edit and remove exam subjects for your class.',
                color: const Color(0xFF10B981),
                accent: primary,
                onTap: () => context.go('/teacher/exams/subjects'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  const _BigActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.85),
                      color.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
