import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/parent/domain/parent_model.dart';
import 'package:mobile_app/features/parent/providers/parent_provider.dart';

class ParentTimetableScreen extends ConsumerStatefulWidget {
  const ParentTimetableScreen({super.key});

  @override
  ConsumerState<ParentTimetableScreen> createState() =>
      _ParentTimetableScreenState();
}

class _ParentTimetableScreenState
    extends ConsumerState<ParentTimetableScreen> {
  String? _selectedChildId;
  int _selectedDay = 1; // 1=Mon … 6=Sat

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Timetable'),
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(parentChildrenProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No children linked to your account',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Auto-select first child
          final effectiveId = _selectedChildId ?? children.first.id;

          return Column(
            children: [
              // ── Child picker ───────────────────────────────────────────────
              if (children.length > 1)
                Container(
                  color: cs.surface,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: effectiveId,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (v) =>
                          setState(() => _selectedChildId = v),
                      items: children
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: _ChildDropdownItem(child: c),
                              ))
                          .toList(),
                    ),
                  ),
                )
              else
                _ChildHeader(child: children.first),

              // ── Day tabs ───────────────────────────────────────────────────
              Container(
                color: cs.surface,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: List.generate(_days.length, (i) {
                      final day = i + 1;
                      final selected = _selectedDay == day;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_days[i]),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedDay = day),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const Divider(height: 1),

              // ── Timetable entries ──────────────────────────────────────────
              Expanded(
                child: _TimetableBody(
                  childId: effectiveId,
                  selectedDay: _selectedDay,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Child header (when only one child) ───────────────────────────────────────

class _ChildHeader extends StatelessWidget {
  const _ChildHeader({required this.child});
  final ChildSummary child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person, color: cs.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(child.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${child.className} ${child.section}'.trim(),
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildDropdownItem extends StatelessWidget {
  const _ChildDropdownItem({required this.child});
  final ChildSummary child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.person, color: cs.onPrimaryContainer, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(child.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${child.className} ${child.section}'.trim(),
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Timetable body ────────────────────────────────────────────────────────────

class _TimetableBody extends ConsumerWidget {
  const _TimetableBody({
    required this.childId,
    required this.selectedDay,
  });
  final String childId;
  final int selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final ttAsync = ref.watch(parentTimetableProvider(childId));

    return ttAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(e.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(parentTimetableProvider(childId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (entries) {
        final dayEntries = entries
            .where((e) => e.dayOfWeek == selectedDay)
            .toList()
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

        if (dayEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_outlined,
                    size: 56, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('No classes scheduled',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: dayEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) =>
              _PeriodCard(entry: dayEntries[i], index: i),
        );
      },
    );
  }
}

// ── Period card ───────────────────────────────────────────────────────────────

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.entry, required this.index});
  final TimetableEntry entry;
  final int index;

  static const _periodColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _periodColors[index % _periodColors.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Period number badge
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${entry.periodNumber}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectName.isNotEmpty
                      ? entry.subjectName
                      : entry.subjectCode,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (entry.subjectCode.isNotEmpty &&
                    entry.subjectName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.subjectCode,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
                if (entry.teacherName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(entry.teacherName,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Period ${entry.periodNumber}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}
