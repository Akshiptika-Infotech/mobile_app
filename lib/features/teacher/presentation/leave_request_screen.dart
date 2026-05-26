import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/teacher/domain/leave_request_model.dart';
import 'package:mobile_app/features/teacher/providers/teacher_leave_provider.dart';

class TeacherLeaveScreen extends ConsumerStatefulWidget {
  const TeacherLeaveScreen({super.key});

  @override
  ConsumerState<TeacherLeaveScreen> createState() =>
      _TeacherLeaveScreenState();
}

class _TeacherLeaveScreenState extends ConsumerState<TeacherLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = AppConfigScope.of(context).primaryColor;
    final leavesAsync = ref.watch(myLeavesProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('My Leaves'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: () async {
          ref.invalidate(myLeavesProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: leavesAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(16),
            child: AppSkeletonLoader.list(count: 6, itemHeight: 110),
          ),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(myLeavesProvider),
          ),
          data: (leaves) {
            final pending = leaves.where((l) => l.isPending).toList();
            final approved = leaves.where((l) => l.isApproved).toList();
            final rejected = leaves.where((l) => l.isRejected).toList();
            return TabBarView(
              controller: _tabs,
              children: [
                _LeaveList(items: pending, emptyMessage: 'No pending requests'),
                _LeaveList(items: approved, emptyMessage: 'No approved leaves yet'),
                _LeaveList(items: rejected, emptyMessage: 'No rejected requests'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () => _openRequestSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request leave'),
      ),
    );
  }

  Future<void> _openRequestSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LeaveRequestSheet(),
    );
    // The form invalidates myLeavesProvider on success, so list refreshes
    // automatically.
  }
}

// ── List ──────────────────────────────────────────────────────────────────────

class _LeaveList extends StatelessWidget {
  const _LeaveList({required this.items, required this.emptyMessage});

  final List<LeaveRequestModel> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(
        message: emptyMessage,
        icon: Icons.event_note_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _LeaveCard(leave: items[i]),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave});
  final LeaveRequestModel leave;

  Color get _statusColor {
    switch (leave.status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get _statusIcon {
    switch (leave.status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  IconData get _typeIcon {
    switch (leave.leaveType.toUpperCase()) {
      case 'SICK':
        return Icons.sick_rounded;
      case 'MEDICAL':
        return Icons.medical_services_rounded;
      case 'MATERNITY':
        return Icons.child_care_rounded;
      case 'EARNED':
        return Icons.beach_access_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM');
    final yr = DateFormat('yyyy');

    final isSameYear = leave.fromDate.year == leave.toDate.year;
    final isSameDay = leave.fromDate.year == leave.toDate.year &&
        leave.fromDate.month == leave.toDate.month &&
        leave.fromDate.day == leave.toDate.day;

    final dateRange = isSameDay
        ? '${fmt.format(leave.fromDate)} ${yr.format(leave.fromDate)}'
        : isSameYear
            ? '${fmt.format(leave.fromDate)} – ${fmt.format(leave.toDate)} ${yr.format(leave.toDate)}'
            : '${fmt.format(leave.fromDate)} ${yr.format(leave.fromDate)} – ${fmt.format(leave.toDate)} ${yr.format(leave.toDate)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: _statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LeaveType.label(leave.leaveType),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$dateRange • ${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 12, color: _statusColor),
                    const SizedBox(width: 4),
                    Text(
                      leave.status[0].toUpperCase() + leave.status.substring(1),
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (leave.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                leave.reason,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (leave.reviewerNote != null &&
              leave.reviewerNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_alt_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    leave.reviewerNote!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Request sheet ─────────────────────────────────────────────────────────────

class _LeaveRequestSheet extends ConsumerStatefulWidget {
  const _LeaveRequestSheet();

  @override
  ConsumerState<_LeaveRequestSheet> createState() =>
      _LeaveRequestSheetState();
}

class _LeaveRequestSheetState extends ConsumerState<_LeaveRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  String _type = LeaveType.casual;
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final initialFirst = _from ?? DateTime.now();
    final initialLast =
        _to ?? initialFirst.add(const Duration(days: 1));
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          DateTimeRange(start: initialFirst, end: initialLast),
      helpText: 'Select leave dates',
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select leave dates')),
      );
      return;
    }
    final ok = await ref.read(leaveSubmissionProvider.notifier).submit(
          fromDate: _from!,
          toDate: _to!,
          leaveType: _type,
          reason: _reasonCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = AppConfigScope.of(context).primaryColor;
    final submission = ref.watch(leaveSubmissionProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final fmt = DateFormat('d MMM yyyy');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.event_note_rounded,
                          color: primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'New leave request',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Leave type',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeaveType.all.map((t) {
                    final selected = _type == t;
                    return ChoiceChip(
                      label: Text(LeaveType.label(t)),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: primary.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: selected ? primary : cs.onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: selected
                            ? primary
                            : cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text('Dates',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range_rounded,
                            color: primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _from == null || _to == null
                                ? 'Tap to select date range'
                                : '${fmt.format(_from!)}  →  ${fmt.format(_to!)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _from == null
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Reason',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  maxLength: 1000,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Briefly describe your reason (min 5 chars)',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.length < 5) return 'At least 5 characters';
                    return null;
                  },
                ),
                if (submission.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: cs.onErrorContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            submission.error!,
                            style: TextStyle(
                                color: cs.onErrorContainer, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: submission.isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: submission.isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Submit request',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
