import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';
import 'package:mobile_app/features/admin/providers/exam_provider.dart';

// ── Class selector ─────────────────────────────────────────────────────────────

final _selectedClassProvider = StateProvider.autoDispose<String?>((ref) => null);

class ReportCardsScreen extends ConsumerWidget {
  const ReportCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedClass = ref.watch(_selectedClassProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Report Cards'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _ClassPickerBar(
            selectedClass: selectedClass,
            onChanged: (c) =>
                ref.read(_selectedClassProvider.notifier).state = c,
          ),
          Expanded(
            child: selectedClass == null
                ? _Placeholder()
                : _ReportList(classId: selectedClass),
          ),
        ],
      ),
    );
  }
}

// ── Class picker ──────────────────────────────────────────────────────────────

class _ClassPickerBar extends StatefulWidget {
  const _ClassPickerBar({required this.selectedClass, required this.onChanged});
  final String? selectedClass;
  final ValueChanged<String?> onChanged;

  @override
  State<_ClassPickerBar> createState() => _ClassPickerBarState();
}

class _ClassPickerBarState extends State<_ClassPickerBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: 'Class ID',
                hintText: 'e.g. class-10-a',
                prefixIcon: const Icon(Icons.class_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) =>
                  widget.onChanged(_ctrl.text.trim().isEmpty
                      ? null
                      : _ctrl.text.trim()),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: () => widget.onChanged(
                _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim()),
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text('Enter a class ID to load report cards',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Report list ───────────────────────────────────────────────────────────────

class _ReportList extends ConsumerWidget {
  const _ReportList({required this.classId});
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cardsAsync = ref.watch(reportCardsProvider(classId));

    return cardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                  maxLines: 3),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ref.refresh(reportCardsProvider(classId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (cards) {
        if (cards.isEmpty) {
          return Center(
            child: Text('No report cards found for this class',
                style: TextStyle(color: cs.onSurfaceVariant)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          itemCount: cards.length,
          itemBuilder: (context, i) => _ReportCardTile(card: cards[i]),
        );
      },
    );
  }
}

// ── Report card tile ──────────────────────────────────────────────────────────

class _ReportCardTile extends StatefulWidget {
  const _ReportCardTile({required this.card});
  final ReportCard card;

  @override
  State<_ReportCardTile> createState() => _ReportCardTileState();
}

class _ReportCardTileState extends State<_ReportCardTile> {
  bool _expanded = false;

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return const Color(0xFF10B981);
      case 'B+':
      case 'B':
        return const Color(0xFF3B82F6);
      case 'C':
        return const Color(0xFFF59E0B);
      case 'D':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = widget.card;
    final gradeColor = _gradeColor(card.grade);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: gradeColor.withValues(alpha: 0.15),
                    child: Text(
                      card.grade.isEmpty ? '?' : card.grade,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.studentName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('${card.className} – ${card.section}',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${card.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: gradeColor),
                      ),
                      Text('Overall',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          // Expanded subject results
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _SubjectTable(subjects: card.subjects),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── Subject table ─────────────────────────────────────────────────────────────

class _SubjectTable extends StatelessWidget {
  const _SubjectTable({required this.subjects});
  final List<SubjectResult> subjects;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(color: cs.outlineVariant),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                    child: Text('Subject',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 56,
                    child: Text('Marks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600))),
                SizedBox(
                    width: 36,
                    child: Text('Grade',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          ...subjects.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.subject,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          Text(s.examType,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: Text(
                        '${s.marksObtained}/${s.maxMarks}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: s.isPassing
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        s.grade,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: s.isPassing
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
