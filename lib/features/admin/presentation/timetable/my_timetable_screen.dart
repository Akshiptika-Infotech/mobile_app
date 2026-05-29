import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/admin/data/timetable_repository.dart';
import 'package:mobile_app/features/admin/domain/timetable_model.dart';
import 'package:mobile_app/features/admin/providers/my_profile_provider.dart';
import 'package:mobile_app/features/admin/providers/timetable_provider.dart';

class MyTimetableScreen extends ConsumerStatefulWidget {
  const MyTimetableScreen({super.key});

  @override
  ConsumerState<MyTimetableScreen> createState() =>
      _MyTimetableScreenState();
}

class _MyTimetableScreenState extends ConsumerState<MyTimetableScreen>
    with SingleTickerProviderStateMixin {
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final todayIndex = (DateTime.now().weekday - 1).clamp(0, 5);
    _tabController =
        TabController(length: _days.length, vsync: this, initialIndex: todayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final periodsAsync = ref.watch(teacherTimetableProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final isMotherTeacher = profileAsync.value?.isMotherTeacher ?? false;
    final assignedClassId = profileAsync.value?.assignedClassId;

    ref.listen(teacherTimetableActionProvider, (prev, next) {
      if (next.success && prev?.success != true) {
        ref.invalidate(teacherTimetableProvider);
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('My Timetable'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _days.map((d) => Tab(text: d.substring(0, 3))).toList(),
        ),
      ),
      body: periodsAsync.when(
        loading: () => _TimetableSkeleton(tabController: _tabController),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(teacherTimetableProvider),
        ),
        data: (periods) => TabBarView(
          controller: _tabController,
          children: _days.asMap().entries.map((entry) {
            final day = entry.value;
            final dayPeriods = periods
                .where((p) => p.day.toLowerCase() == day.toLowerCase())
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
            return _DayView(
              day: day,
              periods: dayPeriods,
              isEditable: isMotherTeacher,
              assignedClassId: assignedClassId,
            );
          }).toList(),
        ),
      ),
      floatingActionButton: isMotherTeacher
          ? FloatingActionButton(
              onPressed: () => _showSlotForm(context, assignedClassId: assignedClassId),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _showSlotForm(
    BuildContext context, {
    TimetablePeriod? period,
    String? assignedClassId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SlotFormSheet(
          period: period,
          assignedClassId: assignedClassId,
          onSave: (data) async {
            final notifier = ref.read(teacherTimetableActionProvider.notifier);
            if (period == null) {
              await notifier.create(
                dayOfWeek: data['dayOfWeek'] as String,
                periodNumber: data['periodNumber'] as int,
                startTime: data['startTime'] as String,
                endTime: data['endTime'] as String,
                subjectId: data['subjectId'] as String,
                sectionId: data['sectionId'] as String?,
                optionSlot: data['optionSlot'] == true,
              );
            } else {
              await notifier.update(
                period.id,
                startTime: data['startTime'] as String?,
                endTime: data['endTime'] as String?,
                subjectId: data['subjectId'] as String?,
              );
            }
          },
        ),
      ),
    );
  }
}

// ── Day view ──────────────────────────────────────────────────────────────────

class _DayView extends ConsumerWidget {
  const _DayView({
    required this.day,
    required this.periods,
    required this.isEditable,
    this.assignedClassId,
  });

  final String day;
  final List<TimetablePeriod> periods;
  final bool isEditable;
  final String? assignedClassId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (periods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No classes on $day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: periods.length,
      itemBuilder: (context, i) => _PeriodCard(
        period: periods[i],
        index: i,
        isEditable: isEditable,
        assignedClassId: assignedClassId,
      ),
    );
  }
}

// ── Period card ───────────────────────────────────────────────────────────────

class _PeriodCard extends ConsumerWidget {
  const _PeriodCard({
    required this.period,
    required this.index,
    required this.isEditable,
    this.assignedClassId,
  });

  final TimetablePeriod period;
  final int index;
  final bool isEditable;
  final String? assignedClassId;

  static const _accentColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final accent = _accentColors[index % _accentColors.length];
    final actionState = ref.watch(teacherTimetableActionProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Time column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          period.startTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(Icons.arrow_downward_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(height: 2),
                        Text(
                          period.endTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 48,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 16),
                    // Subject & class info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period.subject,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.class_rounded,
                                  size: 13, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${period.className} – ${period.section}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Period badge + actions
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'P${period.periodNumber ?? index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        if (isEditable) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                icon: Icon(Icons.edit_rounded,
                                    size: 18, color: cs.primary),
                                onPressed: actionState.isLoading
                                    ? null
                                    : () => _showEdit(context, ref),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                icon: Icon(Icons.delete_rounded,
                                    size: 18, color: cs.error),
                                onPressed: actionState.isLoading
                                    ? null
                                    : () => _confirmDelete(context, ref),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SlotFormSheet(
          period: period,
          assignedClassId: assignedClassId,
          onSave: (data) async {
            final notifier = ref.read(teacherTimetableActionProvider.notifier);
            await notifier.update(
              period.id,
              startTime: data['startTime'] as String?,
              endTime: data['endTime'] as String?,
              subjectId: data['subjectId'] as String?,
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot?'),
        content: Text('Remove "${period.subject}" from ${period.day}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(teacherTimetableActionProvider.notifier)
                  .delete(period.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Slot form sheet ───────────────────────────────────────────────────────────

class _SlotFormSheet extends ConsumerStatefulWidget {
  const _SlotFormSheet({
    this.period,
    this.assignedClassId,
    required this.onSave,
  });

  final TimetablePeriod? period;
  final String? assignedClassId;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  ConsumerState<_SlotFormSheet> createState() => _SlotFormSheetState();
}

class _SlotFormSheetState extends ConsumerState<_SlotFormSheet> {
  late String _dayOfWeek;
  late final TextEditingController _periodCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  String? _selectedSubjectId;
  bool _optionSlot = false;
  bool _isSaving = false;

  static const _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.period;
    _dayOfWeek = p != null
        ? _days.firstWhere(
            (d) => d.toLowerCase() == p.day.toLowerCase(),
            orElse: () => 'MONDAY',
          )
        : 'MONDAY';
    _periodCtrl = TextEditingController(
      text: p?.periodNumber?.toString() ?? '',
    );
    _startCtrl = TextEditingController(text: p?.startTime ?? '');
    _endCtrl = TextEditingController(text: p?.endTime ?? '');
    _selectedSubjectId = p?.subjectId;
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      ctrl.text = '$hour:$minute';
    }
  }

  Future<void> _save() async {
    final isEdit = widget.period != null;
    final startTime = _startCtrl.text.trim();
    final endTime = _endCtrl.text.trim();

    if (startTime.isEmpty || endTime.isEmpty) return;
    if (!isEdit) {
      if (_periodCtrl.text.trim().isEmpty || _selectedSubjectId == null) return;
    } else {
      if (_selectedSubjectId == null) return;
    }

    setState(() => _isSaving = true);
    await widget.onSave({
      if (!isEdit) 'dayOfWeek': _dayOfWeek,
      if (!isEdit)
        'periodNumber': int.tryParse(_periodCtrl.text.trim()) ?? 1,
      'startTime': startTime,
      'endTime': endTime,
      'subjectId': _selectedSubjectId,
      if (!isEdit) 'optionSlot': _optionSlot,
    });
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.period != null;
    final subjectsAsync = widget.assignedClassId != null
        ? ref.watch(timetableSubjectsProvider(widget.assignedClassId!))
        : const AsyncValue<List<TimetableSubject>>.data([]);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Slot' : 'Add Slot',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (!isEdit) ...[
              DropdownButtonFormField<String>(
                value: _dayOfWeek,
                decoration: InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _days.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(d[0] + d.substring(1).toLowerCase()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _dayOfWeek = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _periodCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Period Number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      suffixIcon: const Icon(Icons.access_time_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () => _pickTime(_startCtrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      suffixIcon: const Icon(Icons.access_time_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () => _pickTime(_endCtrl),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            subjectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading subjects: $e',
                  style: TextStyle(color: cs.error)),
              data: (subjects) {
                if (subjects.isEmpty) {
                  return Text(
                    'No timetable subjects available.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: subjects.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedSubjectId = v),
                );
              },
            ),
            if (!isEdit) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Option slot'),
                value: _optionSlot,
                onChanged: (v) => setState(() => _optionSlot = v),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Update' : 'Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _TimetableSkeleton extends StatelessWidget {
  const _TimetableSkeleton({required this.tabController});
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: List.generate(
        6,
        (_) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: 5,
          itemBuilder: (_, i) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _Shimmer(height: 88, radius: 16),
          ),
        ),
      ),
    );
  }
}

// ── Shared shimmer ────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.height, this.radius = 8});
  final double height;
  final double radius;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.06, end: 0.16).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: _anim.value)
              : Colors.black.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: cs.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded,
                  size: 36, color: cs.onErrorContainer),
            ),
            const SizedBox(height: 16),
            Text('Failed to load timetable',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
                maxLines: 3),
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
