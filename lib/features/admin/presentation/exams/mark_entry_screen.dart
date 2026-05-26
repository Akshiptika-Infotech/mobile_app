import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/domain/exam_model.dart';
import 'package:mobile_app/features/admin/providers/exam_provider.dart';

class MarkEntryScreen extends ConsumerWidget {
  const MarkEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final subjectsAsync = ref.watch(examSubjectsProvider);
    final state = ref.watch(markEntryProvider);
    final notifier = ref.read(markEntryProvider.notifier);

    // Show success snackbar
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
          return DropdownButtonFormField<ExamSubject>(
            initialValue: selectedSubject,
            decoration: InputDecoration(
              labelText: 'Select Subject & Exam',
              prefixIcon: const Icon(Icons.book_rounded),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
            ),
            items: subjects.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(
                  '${s.name} – ${s.examType} (${s.className} ${s.section})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (s) {
              if (s != null) onSelected(s);
            },
          );
        },
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
    return Column(
      children: [
        _ExamInfo(subject: subject),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: state.students.length,
            itemBuilder: (context, i) => _StudentMarkRow(
              student: state.students[i],
              maxMarks: subject.maxMarks,
              passingMarks: subject.passingMarks,
              onChanged: (val) =>
                  notifier.setMark(state.students[i].studentId, val),
            ),
          ),
        ),
      ],
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
          _infoBadge('Max', '${subject.maxMarks}', cs),
          const SizedBox(width: 12),
          _infoBadge('Pass', '${subject.passingMarks}', cs),
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
    required this.maxMarks,
    required this.passingMarks,
    required this.onChanged,
  });
  final StudentMark student;
  final int maxMarks;
  final int passingMarks;
  final ValueChanged<int?> onChanged;

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _marksColor(int? val) {
    if (val == null) return Colors.grey;
    if (val >= widget.passingMarks) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final val = widget.student.marksObtained;
    final color = _marksColor(val);

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
            radius: 18,
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
                        fontSize: 13),
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
                Text(widget.student.admissionNumber,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: TextFormField(
              controller: _ctrl,
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
                      color: val != null
                          ? color.withValues(alpha: 0.6)
                          : cs.outline),
                ),
              ),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > widget.maxMarks) {
                  _ctrl.text = widget.maxMarks.toString();
                  _ctrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: _ctrl.text.length));
                  widget.onChanged(widget.maxMarks);
                } else {
                  widget.onChanged(parsed);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Text('/${widget.maxMarks}',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant)),
        ],
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
    if (state.selectedSubject == null || state.students.isEmpty) {
      return const SizedBox();
    }
    final entered =
        state.students.where((s) => s.marksObtained != null).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$entered / ${state.students.length} marks entered',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (state.isSubmitting || entered == 0)
                  ? null
                  : notifier.submit,
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Marks'),
            ),
          ),
        ],
      ),
    );
  }
}
