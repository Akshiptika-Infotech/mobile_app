import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';
import 'package:mobile_app/features/admin/providers/class_provider.dart';
import 'package:mobile_app/features/face/domain/face_model.dart';
import 'package:mobile_app/features/face/providers/face_provider.dart';

class EnrollmentListScreen extends ConsumerStatefulWidget {
  const EnrollmentListScreen({super.key});

  @override
  ConsumerState<EnrollmentListScreen> createState() =>
      _EnrollmentListScreenState();
}

class _EnrollmentListScreenState
    extends ConsumerState<EnrollmentListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  AcademicYear? _year;
  SchoolClass? _class;
  Section? _section;
  String _staffRole = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  EnrollmentParams get _studentParams => EnrollmentParams(
        type: 'student',
        classId: _class?.id,
        sectionId: _section?.id,
        academicYearId: _year?.id,
      );

  EnrollmentParams get _staffParams => EnrollmentParams(
        type: 'staff',
        role: _staffRole == 'all' ? null : _staffRole,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Staff'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _EnrollmentTab(params: _studentParams, type: 'student'),
          _EnrollmentTab(params: _staffParams, type: 'staff'),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        selectedYear: _year,
        selectedClass: _class,
        selectedSection: _section,
        staffRole: _staffRole,
        tabIndex: _tabs.index,
        onApply: (year, cls, sec, role) {
          setState(() {
            _year = year;
            _class = cls;
            _section = sec;
            _staffRole = role;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Enrollment tab ────────────────────────────────────────────────────────────

class _EnrollmentTab extends ConsumerWidget {
  const _EnrollmentTab({required this.params, required this.type});

  final EnrollmentParams params;
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(enrollmentListProvider(params));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(e.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(enrollmentListProvider(params)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (list) => _EnrollmentList(list: list, type: type),
    );
  }
}

class _EnrollmentList extends StatelessWidget {
  const _EnrollmentList({required this.list, required this.type});

  final FaceEnrollmentList list;
  final String type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (list.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.face_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('No records found',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final enrolled = list.items.where((i) => i.enrolled).length;
    final total = list.items.length;

    return Column(
      children: [
        // Progress bar
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: cs.surfaceContainerLow,
          child: Row(
            children: [
              Text('$enrolled / $total enrolled',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: cs.primary)),
              const Spacer(),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? enrolled / total : 0,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHigh,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: list.items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final item = list.items[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.enrolled
                      ? Colors.green.shade100
                      : cs.surfaceContainerHigh,
                  child: Icon(
                    item.enrolled
                        ? Icons.face_retouching_natural_rounded
                        : Icons.face_outlined,
                    color: item.enrolled
                        ? Colors.green.shade700
                        : cs.onSurfaceVariant,
                  ),
                ),
                title: Text(item.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  item.identifier ?? '',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: item.enrolled
                    ? Chip(
                        label: const Text('Enrolled',
                            style: TextStyle(fontSize: 11)),
                        backgroundColor:
                            Colors.green.shade100,
                        labelStyle: TextStyle(
                            color: Colors.green.shade800),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      )
                    : OutlinedButton(
                        onPressed: () =>
                            context.push('/admin/face/register',
                                extra: {
                                  'type': type,
                                  'name': item.name,
                                  'admissionNumber': item.admissionNumber,
                                  'identifier': item.identifier,
                                }),
                        child: const Text('Register',
                            style: TextStyle(fontSize: 12)),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({
    required this.selectedYear,
    required this.selectedClass,
    required this.selectedSection,
    required this.staffRole,
    required this.tabIndex,
    required this.onApply,
  });

  final AcademicYear? selectedYear;
  final SchoolClass? selectedClass;
  final Section? selectedSection;
  final String staffRole;
  final int tabIndex;
  final void Function(AcademicYear?, SchoolClass?, Section?, String) onApply;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  AcademicYear? _year;
  SchoolClass? _class;
  Section? _section;
  String _role = 'all';

  @override
  void initState() {
    super.initState();
    _year = widget.selectedYear;
    _class = widget.selectedClass;
    _section = widget.selectedSection;
    _role = widget.staffRole;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final yearsAsync = ref.watch(academicYearsProvider);
    final classesAsync = ref.watch(classesProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          if (widget.tabIndex == 0) ...[
            // Student filters
            yearsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (years) => _Dropdown<AcademicYear>(
                label: 'Academic Year',
                value: _year,
                items: years,
                labelOf: (y) => y?.name ?? 'All years',
                onChanged: (y) => setState(() => _year = y),
              ),
            ),
            const SizedBox(height: 12),
            classesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (classes) => _Dropdown<SchoolClass>(
                label: 'Class',
                value: _class,
                items: classes,
                labelOf: (c) => c?.name ?? 'All classes',
                onChanged: (c) => setState(() {
                  _class = c;
                  _section = null;
                }),
              ),
            ),
            const SizedBox(height: 12),
            sectionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (all) {
                final secs = all
                    .where((s) => s.classId == _class?.id)
                    .toList();
                if (secs.isEmpty) return const SizedBox.shrink();
                return _Dropdown<Section>(
                  label: 'Section',
                  value: _section,
                  items: secs,
                  labelOf: (s) => s?.name ?? 'All sections',
                  onChanged: (s) => setState(() => _section = s),
                );
              },
            ),
          ] else ...[
            // Staff filters
            _Dropdown<String>(
              label: 'Role',
              value: _role,
              items: const ['all', 'TEACHER', 'ADMIN', 'CLERK', 'DRIVER'],
              labelOf: (r) {
                if (r == null || r == 'all') return 'All roles';
                return r;
              },
              onChanged: (r) => setState(() => _role = r ?? 'all'),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(() {
                  _year = null;
                  _class = null;
                  _section = null;
                  _role = 'all';
                }),
                child: const Text('Clear'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      widget.onApply(_year, _class, _section, _role),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T? item) labelOf;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: value,
              isExpanded: true,
              hint: Text(labelOf(null),
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 14)),
              onChanged: onChanged,
              items: [
                DropdownMenuItem<T?>(
                    value: null, child: Text(labelOf(null))),
                ...items.map((item) => DropdownMenuItem<T?>(
                      value: item,
                      child: Text(labelOf(item),
                          style: const TextStyle(fontSize: 14)),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
