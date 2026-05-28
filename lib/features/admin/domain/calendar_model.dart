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
        return const Color(0xFFEF4444);
      case 'exam':
        return const Color(0xFFF59E0B);
      case 'activity':
        return const Color(0xFF3B82F6);
      case 'meeting':
        return const Color(0xFF8B5CF6);
      case 'event':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
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
