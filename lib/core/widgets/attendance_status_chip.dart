import 'package:flutter/material.dart';

/// Pill-shaped bulk-mark chip (e.g. "Mark all Present").
/// Uses [ColorScheme] colors: primary / error / tertiary for P / A / L.
class AttendanceBulkChip extends StatelessWidget {
  const AttendanceBulkChip({
    super.key,
    required this.label,
    required this.status,
    required this.onTap,
  });

  final String label;

  /// One of: 'present', 'absent', 'late'
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Small circular P / A / L toggle chip for per-row attendance marking.
class AttendanceStatusChip extends StatelessWidget {
  const AttendanceStatusChip({
    super.key,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  /// One of: 'present', 'absent', 'late'
  final String status;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = {'present': 'P', 'absent': 'A', 'late': 'L'};

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context, status);
    final label = _labels[status] ?? status[0].toUpperCase();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? color : color.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

Color _colorFor(BuildContext context, String status) {
  final cs = Theme.of(context).colorScheme;
  return switch (status) {
    'present' => cs.primary,
    'absent' => cs.error,
    'late' => cs.tertiary,
    _ => cs.onSurfaceVariant,
  };
}
