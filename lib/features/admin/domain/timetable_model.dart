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

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    return TimetablePeriod(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      teacherName:
          (json['teacherName'] ?? json['teacher_name'] ?? '').toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      day: (json['day'] ?? '').toString(),
      startTime:
          (json['startTime'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['end_time'] ?? '').toString(),
    );
  }
}
