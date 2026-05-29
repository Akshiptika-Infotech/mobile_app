import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';
import 'package:mobile_app/features/admin/providers/exam_provider.dart';

const _gradeOptions = ['A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'E'];

final _deadlineFormat = DateFormat('d MMM yyyy');

String _formatDeadline(DateTime? d) =>
    d == null ? '—' : _deadlineFormat.format(d);

class MarkEntryScreen extends ConsumerWidget {
  const MarkEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final subjectsAsync = ref.watch(examSubjectsProvider);
    final state = ref.watch(markEntryProvider);
    final notifier = ref.read(markEntryProvider.notifier);

    // Show success / error snackbar
    ref.listen(markEntryProvider, (prev, next) {
      if (next.success && prev?.success != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks submitted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        notifier.reset();
      }
      if (next.draftSaved && prev?.draftSaved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved'),
            backgroundColor: Color(0xFF3B82F6),
          ),
        );
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: cs.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Mark Entry'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _SubjectPicker(
            subjectsAsync: subjectsAsync,
            selectedSubject: state.selectedSubject,
            onSelected: notifier.selectSubject,
          ),
          Expanded(child: _Body(state: state, notifier: notifier)),
        ],
      ),
      bottomNavigationBar: _SubmitBar(state: state, notifier: notifier),
    );
  }
}

// ── Subject picker ────────────────────────────────────────────────────────────

class _SubjectPicker extends StatelessWidget {
  const _SubjectPicker({
    required this.subjectsAsync,
    required this.selectedSubject,
    required this.onSelected,
  });
  final AsyncValue<List<ExamSubject>> subjectsAsync;
  final ExamSubject? selectedSubject;
  final ValueChanged<ExamSubject> onSelected;

  void _openSheet(BuildContext context, List<ExamSubject> subjects) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SubjectSheet(
        subjects: subjects,
        selected: selectedSubject,
        onSelected: (s) {
          onSelected(s);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: subjectsAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Failed to load subjects: $e',
            style: TextStyle(color: cs.error, fontSize: 13)),
        data: (subjects) {
          if (subjects.isEmpty) {
            return Text('No subjects assigned',
                style: TextStyle(color: cs.onSurfaceVariant));
          }
          final s = selectedSubject;
          return Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _openSheet(context, subjects),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.book_rounded, color: cs.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: s == null
                          ? Text(
                              'Select Subject & Exam',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${s.name} – ${s.examType}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.className} • ${s.section}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                    Icon(Icons.unfold_more_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubjectSheet extends StatelessWidget {
  const _SubjectSheet({
    required this.subjects,
    this.selected,
    required this.onSelected,
  });
  final List<ExamSubject> subjects;
  final ExamSubject? selected;
  final ValueChanged<ExamSubject> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Subject & Exam',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: subjects.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = subjects[i];
                  final isSelected = selected?.id == s.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.book_outlined,
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '${s.name} – ${s.examType}',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${s.className} • ${s.section}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: cs.primary)
                        : null,
                    onTap: () => onSelected(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.notifier});
  final MarkEntryState state;
  final MarkEntryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (state.selectedSubject == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_rounded,
                size: 64,
                color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text('Select a subject to enter marks',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.students.isEmpty) {
      return Center(
        child: Text('No students found',
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }

    final subject = state.selectedSubject!;
    final locked = subject.locked;
    final daysLeft = subject.daysUntilDeadline;
    final closingSoon = !locked &&
        daysLeft != null &&
        daysLeft >= 0 &&
        daysLeft <= 3;

    return Column(
      children: [
        _ExamInfo(subject: subject),
        if (locked)
          _LockedNotice(subject: subject)
        else if (closingSoon)
          _ClosingSoonHint(subject: subject, daysLeft: daysLeft),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: state.students.length,
            itemBuilder: (context, i) => _StudentMarkRow(
              student: state.students[i],
              className: subject.className,
              section: subject.section,
              isGraded: subject.isGraded,
              maxMarks: subject.maxMarks,
              passingMarks: subject.passingMarks,
              readOnly: locked,
              onMarkChanged: (val) =>
                  notifier.setMark(state.students[i].studentId, val),
              onGradeChanged: (val) =>
                  notifier.setGrade(state.students[i].studentId, val),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Locked / closing-soon notices ─────────────────────────────────────────────

class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.subject});
  final ExamSubject subject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deadline = subject.marksEntryDeadline;
    final text = deadline != null
        ? 'Marks entry closed (deadline: ${_formatDeadline(deadline)}). '
            'Contact admin to change.'
        : 'Marks entry is closed. Contact admin to change.';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, size: 20, color: cs.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: cs.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingSoonHint extends StatelessWidget {
  const _ClosingSoonHint({required this.subject, required this.daysLeft});
  final ExamSubject subject;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final when = daysLeft == 0
        ? 'today'
        : daysLeft == 1
            ? 'tomorrow'
            : 'in $daysLeft days';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Marks entry closes $when '
              '(${_formatDeadline(subject.marksEntryDeadline)}).',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exam info bar ─────────────────────────────────────────────────────────────

class _ExamInfo extends StatelessWidget {
  const _ExamInfo({required this.subject});
  final ExamSubject subject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.examType,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                Text(subject.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer)),
              ],
            ),
          ),
          if (subject.isGraded)
            _infoBadge('Type', 'Graded', cs)
          else ...[
            _infoBadge('Max', '${subject.maxMarks}', cs),
            const SizedBox(width: 12),
            _infoBadge('Pass', '${subject.passingMarks}', cs),
          ],
        ],
      ),
    );
  }

  Widget _infoBadge(String label, String value, ColorScheme cs) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cs.onPrimaryContainer)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
      ],
    );
  }
}

// ── Student mark row ──────────────────────────────────────────────────────────

class _StudentMarkRow extends StatefulWidget {
  const _StudentMarkRow({
    required this.student,
    required this.className,
    required this.section,
    required this.isGraded,
    required this.maxMarks,
    required this.passingMarks,
    required this.readOnly,
    required this.onMarkChanged,
    required this.onGradeChanged,
  });
  final StudentMark student;
  final String className;
  final String section;
  final bool isGraded;
  final int maxMarks;
  final int passingMarks;
  final bool readOnly;
  final ValueChanged<int?> onMarkChanged;
  final ValueChanged<String?> onGradeChanged;

  @override
  State<_StudentMarkRow> createState() => _StudentMarkRowState();
}

class _StudentMarkRowState extends State<_StudentMarkRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.student.marksObtained?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _StudentMarkRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.student.marksObtained?.toString() != _ctrl.text) {
      _ctrl.text = widget.student.marksObtained?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
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
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            backgroundImage: (widget.student.photoUrl != null &&
                    widget.student.photoUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(widget.student.photoUrl!)
                : null,
            child: (widget.student.photoUrl == null ||
                    widget.student.photoUrl!.isEmpty)
                ? Text(
                    widget.student.studentName.isNotEmpty
                        ? widget.student.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                        fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.student.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${widget.student.admissionNumber} • ${widget.className} ${widget.section}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isGraded)
            _GradePicker(
              grade: widget.student.grade,
              readOnly: widget.readOnly,
              onChanged: widget.onGradeChanged,
            )
          else
            _MarkInput(
              controller: _ctrl,
              maxMarks: widget.maxMarks,
              passingMarks: widget.passingMarks,
              marksObtained: widget.student.marksObtained,
              readOnly: widget.readOnly,
              onChanged: widget.onMarkChanged,
            ),
        ],
      ),
    );
  }
}

// ── Mark input (scored subjects) ──────────────────────────────────────────────

class _MarkInput extends StatelessWidget {
  const _MarkInput({
    required this.controller,
    required this.maxMarks,
    required this.passingMarks,
    required this.marksObtained,
    required this.readOnly,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int maxMarks;
  final int passingMarks;
  final int? marksObtained;
  final bool readOnly;
  final ValueChanged<int?> onChanged;

  Color _marksColor(int? val) {
    if (val == null) return Colors.grey;
    if (val >= passingMarks) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _marksColor(marksObtained);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          child: TextFormField(
            controller: controller,
            enabled: !readOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '—',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: marksObtained != null
                        ? color.withValues(alpha: 0.6)
                        : cs.outline),
              ),
            ),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: readOnly ? cs.onSurfaceVariant : color,
                fontSize: 16),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > maxMarks) {
                controller.text = maxMarks.toString();
                controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length));
                onChanged(maxMarks);
              } else {
                onChanged(parsed);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Text('/$maxMarks',
            style: TextStyle(
                fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── Grade picker (graded subjects) ────────────────────────────────────────────

class _GradePicker extends StatelessWidget {
  const _GradePicker({
    required this.grade,
    required this.readOnly,
    required this.onChanged,
  });

  final String? grade;
  final bool readOnly;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: DropdownButtonFormField<String>(
        initialValue: grade,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Grade',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
        ),
        items: _gradeOptions.map((g) {
          return DropdownMenuItem(
            value: g,
            child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }).toList(),
        // Passing null disables the dropdown (greyed, non-editable).
        onChanged: readOnly ? null : onChanged,
      ),
    );
  }
}

// ── Submit bar ────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.state, required this.notifier});
  final MarkEntryState state;
  final MarkEntryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final subject = state.selectedSubject;
    if (subject == null || state.students.isEmpty) {
      return const SizedBox();
    }

    // Window closed → no save/submit actions; the body already shows the
    // read-only notice with the deadline.
    if (subject.locked) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        color: cs.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Marks entry closed',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final isGraded = subject.isGraded;
    final entered = isGraded
        ? state.students.where((s) => s.grade != null).length
        : state.students.where((s) => s.marksObtained != null).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$entered / ${state.students.length} entries filled',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (state.isSavingDraft || entered == 0)
                      ? null
                      : notifier.saveDraft,
                  child: state.isSavingDraft
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (state.isSubmitting || entered == 0)
                      ? null
                      : notifier.submit,
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Marks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
