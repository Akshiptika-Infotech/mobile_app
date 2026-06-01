import 'package:flutter/material.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    this.endDate,
    this.classId,
    this.targetClass,
    this.sectionId,
    this.sectionName,
    this.color,
  });

  final String id;
  final String title;
  final String description;
  final String type; // maps from eventType
  final String date; // ISO startDate — used for day matching
  final String? endDate; // ISO endDate
  final String? classId;
  final String? targetClass; // resolved class name (from `class.name`)
  final String? sectionId;
  final String? sectionName; // resolved section name (from `section.name`)
  final String? color;

  /// Whether this event covers [day] (date-only), i.e. `day` falls within the
  /// inclusive `[startDate, endDate]` range. A holiday from 3rd–10th June must
  /// show on every day in that span, not only on the start date.
  ///
  /// Matching is done on the ISO date portion (`YYYY-MM-DD`) to mirror how the
  /// backend stores the dates (UTC midnight) and to avoid timezone shifts that
  /// parsing + local conversion would introduce.
  bool coversDay(DateTime day) {
    final start = _isoDateOnly(date);
    if (start == null) return false;
    final end = _isoDateOnly(endDate) ?? start;
    final target = DateTime(day.year, day.month, day.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  static DateTime? _isoDateOnly(String? iso) {
    if (iso == null || iso.length < 10) return null;
    final parts = iso.substring(0, 10).split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Human-readable scope label: "Whole school", "Grade 5 · All", "Grade 5 · A".
  String get scopeLabel {
    if (targetClass == null) return 'Whole school';
    if (sectionName == null) return '$targetClass · All sections';
    return '$targetClass · $sectionName';
  }

  Color get typeColor {
    if (color != null && color!.startsWith('#')) {
      try {
        return Color(int.parse('FF${color!.substring(1)}', radix: 16));
      } catch (_) {}
    }
    switch (type.toLowerCase()) {
      case 'holiday':
        return const Color(0xFFEF4444); // red
      case 'exam':
        return const Color(0xFFF59E0B); // amber
      case 'sports':
        return const Color(0xFF3B82F6); // blue
      case 'cultural':
        return const Color(0xFF8B5CF6); // purple
      case 'meeting':
        return const Color(0xFF0EA5E9); // sky
      case 'ptm':
        return const Color(0xFF10B981); // green
      default: // OTHER
        return const Color(0xFF6B7280); // grey
    }
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    // API returns startDate/endDate (ISO datetime) and eventType.
    final startDate = (json['startDate'] ?? json['date'] ?? '').toString();
    final endDate = json['endDate']?.toString();
    final classObj = json['class'] as Map<String, dynamic>?;
    final sectionObj = json['section'] as Map<String, dynamic>?;
    return CalendarEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['eventType'] ?? json['type'] ?? 'OTHER').toString(),
      date: startDate,
      endDate: endDate,
      classId: json['classId']?.toString(),
      targetClass: classObj?['name']?.toString() ??
          (json['targetClass'] ?? json['target_class'])?.toString(),
      sectionId: json['sectionId']?.toString(),
      sectionName: sectionObj?['name']?.toString(),
      color: json['color']?.toString(),
    );
  }
}
