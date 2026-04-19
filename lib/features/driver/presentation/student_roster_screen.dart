import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/features/driver/domain/driver_model.dart';
import 'package:mobile_app/features/driver/providers/driver_provider.dart';

class StudentRosterScreen extends ConsumerWidget {
  const StudentRosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final studentsAsync = ref.watch(driverStudentsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Student Roster'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(driverStudentsProvider),
          ),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(driverStudentsProvider),
        ),
        data: (students) => _RosterList(students: students),
      ),
    );
  }
}

class _RosterList extends StatefulWidget {
  const _RosterList({required this.students});
  final List<DriverStudent> students;

  @override
  State<_RosterList> createState() => _RosterListState();
}

class _RosterListState extends State<_RosterList> {
  String _query = '';

  List<DriverStudent> get _filtered => _query.isEmpty
      ? widget.students
      : widget.students
          .where((s) =>
              s.name.toLowerCase().contains(_query.toLowerCase()) ||
              s.stoppageName.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Column(
      children: [
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name or stoppage…',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text('${filtered.length} students',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? 'No students' : 'No results for "$_query"',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _StudentCard(student: filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final DriverStudent student;

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
            backgroundColor: cs.primaryContainer,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                  fontSize: 15),
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
                Text(
                  '${student.className} ${student.section}'
                  '${student.stoppageName.isNotEmpty ? ' · ${student.stoppageName}' : ''}',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (student.parentPhone.isNotEmpty)
            IconButton(
              icon: Icon(Icons.call_rounded, color: cs.primary),
              tooltip: 'Call parent',
              onPressed: () => _dial(student.parentPhone),
            ),
        ],
      ),
    );
  }
}

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
