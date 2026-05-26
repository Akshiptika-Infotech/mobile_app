import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/parent/domain/child_model.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';

/// Persistent child picker used on Dashboard, Fees, Receipts, Calendar and
/// Timetable. Renders a single tile when there's exactly one child;
/// otherwise a horizontal scroll row of pills.
class ChildSelector extends ConsumerWidget {
  const ChildSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(childrenProvider);
    final selectedId = ref.watch(selectedChildIdProvider);

    return async.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Failed to load children: $e',
            style: TextStyle(color: cs.error)),
      ),
      data: (children) {
        if (children.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No children linked to your account. Contact the school.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          );
        }
        // Seed default selection on first render.
        if (selectedId == null ||
            children.every((c) => c.id != selectedId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedChildIdProvider.notifier).state =
                children.first.id;
          });
        }

        if (children.length == 1) {
          return _ChildCard(child: children.first, selected: true);
        }

        return SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: children.length,
            itemBuilder: (_, i) {
              final c = children[i];
              final isSelected = c.id == selectedId;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => ref
                      .read(selectedChildIdProvider.notifier)
                      .state = c.id,
                  child: _ChildCard(child: c, selected: isSelected),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.selected});
  final ParentChild child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPhoto = (child.photoPath ?? '').isNotEmpty;
    final subtitleParts = <String>[
      if (child.className != null) child.className!,
      if (child.section != null) child.section!,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? cs.primary : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: selected ? Colors.white24 : cs.primaryContainer,
            backgroundImage: hasPhoto
                ? CachedNetworkImageProvider(child.photoPath!)
                : null,
            child: hasPhoto
                ? null
                : Text(child.initials,
                    style: TextStyle(
                        color: selected
                            ? Colors.white
                            : cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(child.name,
                  style: TextStyle(
                      color: selected ? Colors.white : cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (subtitleParts.isNotEmpty)
                Text(
                  subtitleParts.join(' · '),
                  style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : cs.onSurfaceVariant,
                      fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
