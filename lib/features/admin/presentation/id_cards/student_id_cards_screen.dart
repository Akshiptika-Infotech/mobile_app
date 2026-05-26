import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_search_bar.dart';
import 'package:mobile_app/features/admin/domain/id_card_model.dart';
import 'package:mobile_app/features/admin/providers/id_card_provider.dart';

class StudentIdCardsScreen extends ConsumerStatefulWidget {
  const StudentIdCardsScreen({super.key});

  @override
  ConsumerState<StudentIdCardsScreen> createState() => _StudentIdCardsScreenState();
}

class _StudentIdCardsScreenState extends ConsumerState<StudentIdCardsScreen> {
  String? _selectedClass;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(idCardProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Student ID Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(idCardProvider.notifier).load(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.isLoading) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        }
        if (state.error != null) {
          return AppErrorState(
            message: state.error!,
            onRetry: () => ref.read(idCardProvider.notifier).load(),
          );
        }

        final cards = state.idCards;

        // Distinct class names
        final classes = cards.map((c) => c.className).where((c) => c.isNotEmpty).toSet().toList()
          ..sort();

        final filtered = cards.where((c) {
          final matchClass = _selectedClass == null || c.className == _selectedClass;
          final matchSearch = _searchQuery.isEmpty ||
              c.studentName.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchClass && matchSearch;
        }).toList();

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AppSearchBar(
                hintText: 'Search by name...',
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ),
            // Class filter chips
            if (classes.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedClass == null,
                        onSelected: (_) => setState(() => _selectedClass = null),
                      ),
                    ),
                    ...classes.map((cls) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cls),
                            selected: _selectedClass == cls,
                            onSelected: (_) => setState(() => _selectedClass = cls),
                          ),
                        )),
                  ],
                ),
              ),
            // Grid
            Expanded(
              child: filtered.isEmpty
                  ? const AppEmptyState(
                      message: 'No ID cards found',
                      icon: Icons.badge_outlined,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _IdCard(
                        card: filtered[i],
                        onGenerate: () =>
                            ref.read(idCardProvider.notifier).generate(
                              studentIds: [filtered[i].studentId],
                            ),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

// ── ID Card widget ────────────────────────────────────────────────────────────

class _IdCard extends StatelessWidget {
  const _IdCard({required this.card, required this.onGenerate});
  final IdCardModel card;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: cs.primaryContainer,
              child: Text(
                card.studentName.isNotEmpty ? card.studentName[0].toUpperCase() : '?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.studentName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            if (card.className.isNotEmpty)
              Text(
                'Class ${card.className}',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            if (card.studentId.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'ID: ${card.studentId}',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('PDF generation requires device package (Phase M9)')),
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 14),
                label: const Text('Generate', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
