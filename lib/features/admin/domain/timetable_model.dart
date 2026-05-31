class TimetablePeriod {
  const TimetablePeriod({
    required this.id,
    this.subjectId,
    required this.subject,
    required this.teacherName,
    this.teacherId,
    this.classId,
    required this.className,
    this.sectionId,
    required this.section,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.periodNumber,
    this.optionSlot = false,
  });

  final String id;
  final String? subjectId;
  final String subject;
  final String teacherName;

  /// Backend `teacher.id` — used to decide whether the signed-in teacher may
  /// edit this period. In the "My Class" (scope=class) grid every teacher's
  /// periods are shown, but only the current teacher's own periods are
  /// editable.
  final String? teacherId;
  final String? classId;
  final String className;
  final String? sectionId;
  final String section;
  final String day; // Monday–Saturday
  final String startTime;
  final String endTime;
  final int? periodNumber;
  final bool optionSlot;

  static String _readName(dynamic v) {
    if (v is String) return v;
    if (v is Map<String, dynamic>) return (v['name'] ?? '').toString();
    return '';
  }

  static String? _readId(dynamic v) {
    if (v is Map<String, dynamic>) return v['id']?.toString();
    return null;
  }

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    return TimetablePeriod(
      id: (json['id'] ?? '').toString(),
      subjectId: _readId(json['subject']),
      subject: _readName(json['subject']),
      teacherName: _readName(json['teacher']),
      teacherId: _readId(json['teacher']) ?? json['teacherUserId']?.toString(),
      classId: _readId(json['class']) ?? json['classId']?.toString(),
      className: _readName(json['class']).isNotEmpty
          ? _readName(json['class'])
          : (json['className'] ?? '').toString(),
      sectionId: _readId(json['section']),
      section: _readName(json['section']),
      // Backend may return dayOfWeek as "MON", "MONDAY", or "Monday" —
      // normalize to a full title-case name so the screen filter matches.
      day: _normalizeDay((json['dayOfWeek'] ?? json['day'] ?? '').toString()),
      startTime:
          (json['startTime'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['end_time'] ?? '').toString(),
      periodNumber: json['periodNumber'] != null
          ? int.tryParse(json['periodNumber'].toString())
          : null,
      optionSlot: json['optionSlot'] == true,
    );
  }

  static String _normalizeDay(String raw) {
    if (raw.isEmpty) return '';
    final key = raw.trim().toUpperCase();
    const map = {
      'MON': 'Monday',
      'MONDAY': 'Monday',
      'TUE': 'Tuesday',
      'TUES': 'Tuesday',
      'TUESDAY': 'Tuesday',
      'WED': 'Wednesday',
      'WEDS': 'Wednesday',
      'WEDNESDAY': 'Wednesday',
      'THU': 'Thursday',
      'THUR': 'Thursday',
      'THURS': 'Thursday',
      'THURSDAY': 'Thursday',
      'FRI': 'Friday',
      'FRIDAY': 'Friday',
      'SAT': 'Saturday',
      'SATURDAY': 'Saturday',
      'SUN': 'Sunday',
      'SUNDAY': 'Sunday',
    };
    return map[key] ?? raw;
  }
}
