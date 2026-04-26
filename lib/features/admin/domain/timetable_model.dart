class TimetablePeriod {
  const TimetablePeriod({
    required this.id,
    required this.subject,
    required this.teacherName,
    required this.className,
    required this.section,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String subject;
  final String teacherName;
  final String className;
  final String section;
  final String day; // Monday–Saturday
  final String startTime;
  final String endTime;

  static String _readName(dynamic v) {
    if (v is String) return v;
    if (v is Map<String, dynamic>) return (v['name'] ?? '').toString();
    return '';
  }

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    return TimetablePeriod(
      id: (json['id'] ?? '').toString(),
      subject: _readName(json['subject']),
      teacherName: _readName(json['teacher']),
      className: _readName(json['class']).isNotEmpty
          ? _readName(json['class'])
          : (json['className'] ?? '').toString(),
      section: _readName(json['section']),
      // Backend returns dayOfWeek as an uppercase enum like "MONDAY".
      day: (json['dayOfWeek'] ?? json['day'] ?? '').toString(),
      startTime:
          (json['startTime'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['end_time'] ?? '').toString(),
    );
  }
}
