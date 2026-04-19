import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/student_model.dart';
import 'package:mobile_app/features/admin/providers/student_provider.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return studentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Student Detail')),
        body: _ErrorBody(
          message: error.toString(),
          onRetry: () => ref.refresh(studentDetailProvider(studentId)),
        ),
      ),
      data: (student) => _StudentDetailBody(
        student: student,
        studentId: studentId,
      ),
    );
  }
}

class _StudentDetailBody extends StatelessWidget {
  const _StudentDetailBody({
    required this.student,
    required this.studentId,
  });
  final StudentModel student;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(
                background: _StudentHeroHeader(
                    student: student, colorScheme: colorScheme),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.push('/admin/students/$studentId/edit'),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Personal'),
                  Tab(text: 'Academic'),
                  Tab(text: 'Parent'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _PersonalTab(student: student),
              _AcademicTab(student: student),
              _ParentTab(student: student),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentHeroHeader extends StatelessWidget {
  const _StudentHeroHeader(
      {required this.student, required this.colorScheme});
  final StudentModel student;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Row(
            children: [
              if (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: CachedNetworkImageProvider(student.photoUrl!),
                )
              else
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      colorScheme.onPrimary.withValues(alpha: 0.2),
                  child: Text(
                    student.initials,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      student.name,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.className} - ${student.section}',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimary
                                    .withValues(alpha: 0.85),
                              ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        student.status.toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Personal Tab ──────────────────────────────────────────────────────────────

class _PersonalTab extends StatelessWidget {
  const _PersonalTab({required this.student});
  final StudentModel student;

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoSection(title: 'Basic Information', items: [
          _InfoItem('Date of Birth', _formatDate(student.dob)),
          _InfoItem('Gender', student.gender ?? '—'),
          _InfoItem('Blood Group', student.bloodGroup ?? '—'),
          _InfoItem('Religion', student.religion ?? '—'),
          _InfoItem('Category', student.category ?? '—'),
          _InfoItem('House', student.house ?? '—'),
        ]),
        const SizedBox(height: 16),
        _InfoSection(title: 'Address', items: [
          _InfoItem('Address', student.address ?? '—'),
        ]),
      ],
    );
  }
}

// ── Academic Tab ──────────────────────────────────────────────────────────────

class _AcademicTab extends StatelessWidget {
  const _AcademicTab({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoSection(title: 'Academic Details', items: [
          _InfoItem('Class', student.className),
          _InfoItem('Section', student.section),
          _InfoItem('Roll Number', student.rollNumber),
          _InfoItem('Admission Number', student.admissionNumber),
          _InfoItem('Academic Year', student.academicYear ?? '—'),
          _InfoItem('Transport Route', student.transportRoute ?? '—'),
        ]),
      ],
    );
  }
}

// ── Parent Tab ────────────────────────────────────────────────────────────────

class _ParentTab extends StatelessWidget {
  const _ParentTab({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoSection(title: "Father's Information", items: [
          _InfoItem('Name', student.fatherName ?? '—'),
          _InfoItem('Phone', student.fatherPhone ?? '—'),
          _InfoItem('Occupation', student.fatherOccupation ?? '—'),
        ]),
        const SizedBox(height: 16),
        _InfoSection(title: "Mother's Information", items: [
          _InfoItem('Name', student.motherName ?? '—'),
          _InfoItem('Phone', student.motherPhone ?? '—'),
          _InfoItem('Occupation', student.motherOccupation ?? '—'),
        ]),
        const SizedBox(height: 16),
        _InfoSection(title: 'Contact', items: [
          _InfoItem('Parent Email', student.parentEmail ?? '—'),
        ]),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});
  final String title;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...items.expand((item) => [
                  _buildRow(context, item, colorScheme),
                  if (item != items.last)
                    Divider(
                        height: 16,
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                ]),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
      BuildContext context, _InfoItem item, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            item.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(
            item.value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);
  final String label;
  final String value;
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load student',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
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
