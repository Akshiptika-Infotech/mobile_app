import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/parent/domain/parent_model.dart';
import 'package:mobile_app/features/parent/providers/parent_provider.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);
    final yearsAsync = ref.watch(parentAcademicYearsProvider);
    final effectiveYearId = ref.watch(effectiveParentYearIdProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.85)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.name ?? 'Parent',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout,
                                color: Colors.white),
                            tooltip: 'Sign out',
                            onPressed: () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .logout();
                              if (context.mounted) context.go('/login');
                            },
                          ),
                        ],
                      ),
                      // Academic year picker
                      const SizedBox(height: 12),
                      yearsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (years) => years.isEmpty
                            ? const SizedBox.shrink()
                            : _YearDropdown(
                                years: years,
                                selectedId: effectiveYearId,
                                onChanged: (id) => ref
                                    .read(selectedParentYearIdProvider
                                        .notifier)
                                    .state = id,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── My Children ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'My Children',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          childrenAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(e.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(parentChildrenProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            data: (children) {
              if (children.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.child_care_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No children linked to your account',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _ChildCard(
                      child: children[index],
                      onTap: () => context.push(
                          '/parent/children/${children[index].id}'),
                    ),
                  ),
                  childCount: children.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Year Dropdown ─────────────────────────────────────────────────────────────

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({
    required this.years,
    required this.selectedId,
    required this.onChanged,
  });

  final List<AcademicYear> years;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          dropdownColor: const Color(0xFF6D28D9),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          onChanged: onChanged,
          items: years
              .map((y) => DropdownMenuItem(
                    value: y.id,
                    child: Text(
                      '${y.name}${y.isActive ? ' (Current)' : ''}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Child Card ────────────────────────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.onTap});

  final ChildSummary child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(0xFF7C3AED).withValues(alpha: 0.15),
                radius: 24,
                child: const Icon(Icons.person, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child.className} ${child.section}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    if (child.admissionNumber.isNotEmpty)
                      Text(
                        'Adm: ${child.admissionNumber}',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
