/// One day's attendance for a student — returned by
/// `GET /api/parent/attendance?studentId=&month=YYYY-MM`.
class StudentAttendanceDay {
  const StudentAttendanceDay({
    required this.date,
    required this.status,
    this.markedAt,
    this.markedByName,
    this.remarks,
  });

  /// Local-date string `YYYY-MM-DD`.
  final String date;
  final AttendanceStatus status;
  final DateTime? markedAt;
  final String? markedByName;
  final String? remarks;

  factory StudentAttendanceDay.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceDay(
      date: (json['date'] ?? '').toString(),
      status: AttendanceStatus.parse(json['status']?.toString()),
      markedAt: DateTime.tryParse(json['markedAt']?.toString() ?? ''),
      markedByName: json['markedByName']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }
}

enum AttendanceStatus {
  present('PRESENT', 'Present'),
  absent('ABSENT', 'Absent'),
  late('LATE', 'Late'),
  leave('LEAVE', 'Leave'),
  holiday('HOLIDAY', 'Holiday'),
  unmarked('UNMARKED', 'Unmarked');

  const AttendanceStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AttendanceStatus parse(String? raw) {
    final v = raw?.toUpperCase();
    return AttendanceStatus.values.firstWhere(
      (e) => e.apiValue == v,
      orElse: () => AttendanceStatus.unmarked,
    );
  }
}

class StudentAttendanceSummary {
  const StudentAttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.totalMarked,
  });

  final int present;
  final int absent;
  final int late;
  final int leave;
  final int totalMarked;

  double get presentPct =>
      totalMarked == 0 ? 0 : (present / totalMarked) * 100;

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      StudentAttendanceSummary(
        present: _i(json['present']),
        absent: _i(json['absent']),
        late: _i(json['late']),
        leave: _i(json['leave']),
        totalMarked: _i(json['totalMarked']),
      );

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
