import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/dashboard_avatar.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';
import 'package:mobile_app/features/student/providers/student_portal_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final yearsAsync = ref.watch(studentAcademicYearsProvider);
    final effectiveYearId = ref.watch(effectiveStudentYearIdProvider);
    final feeAsync = ref.watch(studentFeeMatrixProvider);
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

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
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
                          DashboardAvatar(
                            radius: 22,
                            imageUrl: user?.image,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            onTap: () => context.go('/student/profile'),
                            fallback: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good day,',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.name ?? 'Student',
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
                            icon:
                                const Icon(Icons.logout, color: Colors.white),
                            tooltip: 'Sign out',
                            onPressed: () async {
                              await ref.read(authProvider.notifier).logout();
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
                                    .read(selectedStudentYearIdProvider
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

          // ── Fee Summary ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Fee Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: feeAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              ref.invalidate(studentFeeMatrixProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (matrix) {
                if (matrix == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      _FeeSummaryCard(
                        label: 'Total',
                        amount: currency.format(matrix.totalNet),
                        color: const Color(0xFFF59E0B),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(width: 8),
                      _FeeSummaryCard(
                        label: 'Paid',
                        amount: currency.format(matrix.totalPaid),
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 8),
                      _FeeSummaryCard(
                        label: 'Due',
                        amount: currency.format(matrix.totalOutstanding),
                        color: matrix.totalOutstanding > 0
                            ? Colors.red
                            : Colors.green,
                        icon: Icons.pending_outlined,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Quick Actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Row(
                children: [
                  _QuickActionCard(
                    icon: Icons.receipt_long,
                    label: 'Fee Matrix',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.go('/student/fees'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.article_outlined,
                    label: 'Receipts',
                    color: Colors.blue,
                    onTap: () => context.go('/student/receipts'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.directions_bus,
                    label: 'Transport',
                    color: Colors.teal,
                    onTap: () => context.go('/student/transport'),
                  ),
                ],
              ),
            ),
          ),
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
          dropdownColor: const Color(0xFFD97706),
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

// ── Widgets ───────────────────────────────────────────────────────────────────

class _FeeSummaryCard extends StatelessWidget {
  const _FeeSummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                amount,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
