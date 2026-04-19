import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/driver/domain/driver_model.dart';
import 'package:mobile_app/features/driver/providers/driver_provider.dart';

class BusAttendanceScreen extends ConsumerStatefulWidget {
  const BusAttendanceScreen({super.key});

  @override
  ConsumerState<BusAttendanceScreen> createState() =>
      _BusAttendanceScreenState();
}

class _BusAttendanceScreenState extends ConsumerState<BusAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tripType = _tabController.index == 0 ? 'morning' : 'afternoon';
        ref.read(busAttendanceProvider.notifier).load(tripType);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(busAttendanceProvider);
    final notifier = ref.read(busAttendanceProvider.notifier);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Bus Attendance'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          if (!state.submitted && state.students.isNotEmpty)
            TextButton.icon(
              onPressed: () => notifier.markAll('present'),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('All Present'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny_rounded), text: 'Morning'),
            Tab(icon: Icon(Icons.nights_stay_rounded), text: 'Afternoon'),
          ],
        ),
      ),
      body: _Body(state: state, notifier: notifier),
      bottomNavigationBar: _SubmitBar(state: state, notifier: notifier),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.notifier});
  final BusAttendanceState state;
  final BusAttendanceNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                  maxLines: 3),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => notifier.load(state.tripType),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_outlined,
                size: 64,
                color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text('No students on this trip',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: state.students.length,
      itemBuilder: (context, i) => _StudentRow(
        student: state.students[i],
        submitted: state.submitted,
        onChanged: (status) =>
            notifier.setStatus(state.students[i].id, status),
      ),
    );
  }
}

// ── Student row ───────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.submitted,
    required this.onChanged,
  });
  final DriverStudent student;
  final bool submitted;
  final ValueChanged<String> onChanged;

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
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (student.stoppageName.isNotEmpty)
                  Text(student.stoppageName,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (submitted)
            _StatusBadge(status: student.status)
          else
            Row(
              children: ['present', 'absent', 'not_boarded'].map((s) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _StatusButton(
                    status: s,
                    selected: student.status == s,
                    onTap: () => onChanged(s),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.selected,
    required this.onTap,
  });
  final String status;
  final bool selected;
  final VoidCallback onTap;

  static const _colors = {
    'present': Color(0xFF10B981),
    'absent': Color(0xFFEF4444),
    'not_boarded': Color(0xFF6B7280),
  };
  static const _labels = {
    'present': 'P',
    'absent': 'A',
    'not_boarded': 'NB',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    final label = _labels[status] ?? status;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? color : color.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  static const _colors = {
    'present': Color(0xFF10B981),
    'absent': Color(0xFFEF4444),
    'not_boarded': Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    final label = status == 'not_boarded'
        ? 'Not Boarded'
        : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Submit bar ────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.state, required this.notifier});
  final BusAttendanceState state;
  final BusAttendanceNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (state.students.isEmpty || state.isLoading) return const SizedBox();
    final cs = Theme.of(context).colorScheme;

    if (state.submitted) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        color: cs.surface,
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text('Attendance submitted',
                style: TextStyle(
                    color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final present = state.students.where((s) => s.status == 'present').length;
    final absent = state.students.where((s) => s.status == 'absent').length;
    final notBoarded =
        state.students.where((s) => s.status == 'not_boarded').length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Count('Present', present, const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _Count('Absent', absent, const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _Count('Not Boarded', notBoarded, const Color(0xFF6B7280)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.isSubmitting ? null : notifier.submit,
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Attendance'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
