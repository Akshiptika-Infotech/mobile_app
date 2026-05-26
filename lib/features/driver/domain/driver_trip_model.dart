/// Bus trip — used for both list (`GET /api/driver/trips`) and detail
/// (`GET /api/driver/trips/:id/attendance`).
class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.tripDate,
    required this.tripType,
    required this.status,
    this.remarks,
    this.attendance = const [],
  });

  final String id;
  final String routeId;
  final String routeName;
  final DateTime tripDate;
  final TripType tripType;
  final TripStatus status;
  final String? remarks;
  final List<TripAttendance> attendance;

  bool get isActive => status == TripStatus.inProgress;
  bool get isCompleted => status == TripStatus.completed;

  int get markedCount => attendance
      .where((a) => a.status != AttendanceStatus.notBoarded)
      .length;
  bool get allMarked =>
      attendance.isNotEmpty && markedCount == attendance.length;

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    final route = json['route'];
    final attList = (json['attendance'] as List? ?? const []);
    return DriverTrip(
      id: (json['id'] ?? '').toString(),
      routeId: (json['routeId'] ?? '').toString(),
      routeName:
          route is Map ? (route['name'] ?? '').toString() : '',
      tripDate:
          DateTime.tryParse(json['tripDate']?.toString() ?? '') ??
              DateTime.now(),
      tripType: TripType.parse(json['tripType']?.toString()),
      status: TripStatus.parse(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
      attendance: attList
          .map((a) => TripAttendance.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  DriverTrip copyWith({
    TripStatus? status,
    List<TripAttendance>? attendance,
  }) {
    return DriverTrip(
      id: id,
      routeId: routeId,
      routeName: routeName,
      tripDate: tripDate,
      tripType: tripType,
      status: status ?? this.status,
      remarks: remarks,
      attendance: attendance ?? this.attendance,
    );
  }
}

class TripAttendance {
  const TripAttendance({
    required this.id,
    required this.studentId,
    required this.stoppageId,
    required this.stoppageName,
    required this.studentName,
    required this.admissionNumber,
    this.photoUrl,
    this.className,
    this.section,
    required this.status,
    this.markedAt,
  });

  final String id;
  final String studentId;
  final String stoppageId;
  final String stoppageName;
  final String studentName;
  final String admissionNumber;
  final String? photoUrl;
  final String? className;
  final String? section;
  final AttendanceStatus status;
  final DateTime? markedAt;

  factory TripAttendance.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final stoppage = json['stoppage'] as Map<String, dynamic>?;
    final cls = student?['class'];
    final sec = student?['section'];
    final first = (student?['firstName'] ?? '').toString();
    final last = (student?['lastName'] ?? '').toString();
    final name = '$first $last'.trim();
    return TripAttendance(
      id: (json['id'] ?? '').toString(),
      studentId: (json['studentId'] ?? student?['id'] ?? '').toString(),
      stoppageId: (json['stoppageId'] ?? '').toString(),
      stoppageName: stoppage != null
          ? (stoppage['name'] ?? '').toString()
          : '',
      studentName: name.isNotEmpty ? name : '',
      admissionNumber:
          (student?['admissionNumber'] ?? '').toString(),
      photoUrl: (student?['photoUrl'] ?? student?['photoPath'])?.toString(),
      className: cls is Map ? cls['name']?.toString() : null,
      section: sec is Map ? sec['name']?.toString() : null,
      status: AttendanceStatus.parse(json['status']?.toString()),
      markedAt: DateTime.tryParse(json['markedAt']?.toString() ?? ''),
    );
  }

  TripAttendance copyWith({AttendanceStatus? status}) => TripAttendance(
        id: id,
        studentId: studentId,
        stoppageId: stoppageId,
        stoppageName: stoppageName,
        studentName: studentName,
        admissionNumber: admissionNumber,
        photoUrl: photoUrl,
        className: className,
        section: section,
        status: status ?? this.status,
        markedAt: DateTime.now(),
      );
}

enum TripType {
  morning('MORNING', 'Morning'),
  // Backend enum is AFTERNOON; UI label is "Evening" per product decision.
  afternoon('AFTERNOON', 'Evening');

  const TripType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static TripType parse(String? raw) {
    final v = raw?.toUpperCase();
    return TripType.values.firstWhere(
      (t) => t.apiValue == v,
      orElse: () => TripType.morning,
    );
  }
}

enum TripStatus {
  scheduled('SCHEDULED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const TripStatus(this.apiValue);
  final String apiValue;

  static TripStatus parse(String? raw) {
    final v = raw?.toUpperCase();
    return TripStatus.values.firstWhere(
      (t) => t.apiValue == v,
      orElse: () => TripStatus.scheduled,
    );
  }
}

enum AttendanceStatus {
  present('PRESENT', 'Present'),
  absent('ABSENT', 'Absent'),
  notBoarded('NOT_BOARDED', 'Not boarded');

  const AttendanceStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AttendanceStatus parse(String? raw) {
    final v = raw?.toUpperCase();
    return AttendanceStatus.values.firstWhere(
      (s) => s.apiValue == v,
      orElse: () => AttendanceStatus.notBoarded,
    );
  }
}
