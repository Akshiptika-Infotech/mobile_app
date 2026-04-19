import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionHeader('Academics'),
          _MenuGrid(items: [
            _MenuItem('Calendar', Icons.event_outlined, '/admin/calendar'),
            _MenuItem('Timetable', Icons.calendar_view_week_outlined, '/admin/timetable'),
            _MenuItem('Attendance', Icons.fact_check_outlined, '/admin/attendance/students'),
            _MenuItem('Leave Requests', Icons.request_page_outlined, '/admin/attendance/leaves'),
            _MenuItem('Reports', Icons.bar_chart_outlined, '/admin/reports/fee-collection'),
            _MenuItem('Certificates', Icons.workspace_premium_outlined, '/admin/certificates/issued'),
            _MenuItem('ID Cards', Icons.badge_outlined, '/admin/id-cards/students'),
          ]),
          SizedBox(height: 16),
          _SectionHeader('Administration'),
          _MenuGrid(items: [
            _MenuItem('Users', Icons.manage_accounts_outlined, '/admin/users'),
            _MenuItem('Masters', Icons.tune_outlined, '/admin/masters/religion'),
            _MenuItem('Classes', Icons.school_outlined, '/admin/classes'),
            _MenuItem('Academic Years', Icons.date_range_outlined, '/admin/academic-years'),
            _MenuItem('Notifications', Icons.notifications_outlined, '/admin/notifications/send'),
            _MenuItem('Face Enroll', Icons.face_retouching_natural_outlined, '/admin/face/enrollment'),
            _MenuItem('DigiLocker', Icons.lock_outlined, '/admin/digilocker-pins'),
            _MenuItem('Settings', Icons.settings_outlined, '/admin/settings'),
          ]),
          SizedBox(height: 16),
          _SectionHeader('Fee Masters'),
          _MenuGrid(items: [
            _MenuItem('Fee Types', Icons.category_outlined, '/admin/fee-masters/types'),
            _MenuItem('Fee Structures', Icons.table_chart_outlined, '/admin/fee-masters/structures'),
            _MenuItem('Concessions', Icons.discount_outlined, '/admin/fee-masters/concessions'),
            _MenuItem('Late Fee', Icons.schedule_outlined, '/admin/fee-masters/late-fee'),
          ]),
          SizedBox(height: 16),
          _SectionHeader('Transport'),
          _MenuGrid(items: [
            _MenuItem('Routes', Icons.route_outlined, '/admin/transport/routes'),
            _MenuItem('Assignments', Icons.directions_bus_outlined, '/admin/transport/assignments'),
            _MenuItem('Rebates', Icons.savings_outlined, '/admin/transport/rebates'),
          ]),
          SizedBox(height: 16),
          _SectionHeader('Gate & Reception'),
          _MenuGrid(items: [
            _MenuItem('Visitors', Icons.person_add_outlined, '/admin/gate/visitors'),
            _MenuItem('Gate Passes', Icons.verified_outlined, '/admin/gate/gate-passes'),
            _MenuItem('Entry/Exit Log', Icons.swap_horiz_outlined, '/admin/gate/entry-exit-log'),
            _MenuItem('Call Log', Icons.call_outlined, '/admin/reception/call-log'),
            _MenuItem('Appointments', Icons.event_available_outlined, '/admin/reception/appointments'),
            _MenuItem('Late Arrivals', Icons.running_with_errors_outlined, '/admin/reception/late-arrivals'),
          ]),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(item.path),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: cs.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface,
                    height: 1.2,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
