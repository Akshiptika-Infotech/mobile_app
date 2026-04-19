import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/admin/domain/student_model.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final myClassStudentsProvider =
    FutureProvider.autoDispose<List<StudentModel>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final res = await dio.get('/api/admin/students');
  final data = res.data;
  final list = (data is List
      ? data
      : (data['students'] ?? data['data'] ?? <dynamic>[])) as List;
  return list
      .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class MyClassStudentsScreen extends ConsumerWidget {
  const MyClassStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final studentsAsync = ref.watch(myClassStudentsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('My Class'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(myClassStudentsProvider),
          ),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(myClassStudentsProvider),
        ),
        data: (students) => _StudentModelList(students: students),
      ),
    );
  }
}

// ── StudentModel list ──────────────────────────────────────────────────────────────

class _StudentModelList extends StatefulWidget {
  const _StudentModelList({required this.students});
  final List<StudentModel> students;

  @override
  State<_StudentModelList> createState() => _StudentModelListState();
}

class _StudentModelListState extends State<_StudentModelList> {
  String _query = '';

  List<StudentModel> get _filtered => _query.isEmpty
      ? widget.students
      : widget.students
          .where((s) =>
              s.name.toLowerCase().contains(_query.toLowerCase()) ||
              s.rollNumber.toLowerCase().contains(_query.toLowerCase()) ||
              s.admissionNumber.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Column(
      children: [
        // Search bar
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name or roll number…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        // Count bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} student${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? 'No students found' : 'No results for "$_query"',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _StudentModelCard(
                    student: filtered[i],
                    index: i,
                    onTap: () => context.push('/admin/students/${filtered[i].id}'),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── StudentModel card ──────────────────────────────────────────────────────────────

class _StudentModelCard extends StatelessWidget {
  const _StudentModelCard({required this.student, required this.index, this.onTap});
  final StudentModel student;
  final int index;
  final VoidCallback? onTap;

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _colors[index % _colors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(student.admissionNumber,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    if (student.rollNumber.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('· Roll ${student.rollNumber}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${student.className} ${student.section}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            const Text('Failed to load students',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
                maxLines: 3),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
