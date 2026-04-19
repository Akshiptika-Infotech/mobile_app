class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.vehicleNumber,
    required this.stoppageCount,
    required this.studentCount,
    required this.tripStatus,
    required this.tripType,
  });

  final String id;
  final String routeId;
  final String routeName;
  final String vehicleNumber;
  final int stoppageCount;
  final int studentCount;
  final String tripStatus;
  final String tripType;

  // From GET /api/driver/trips response item
  factory DriverTrip.fromTripJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>?;
    return DriverTrip(
      id: (json['id'] ?? '').toString(),
      routeId: (json['routeId'] ?? json['route_id'] ?? '').toString(),
      routeName: route != null
          ? (route['name'] ?? '').toString()
          : (json['routeName'] ?? json['route_name'] ?? '').toString(),
      vehicleNumber: (json['vehicleNumber'] ?? json['vehicle_number'] ?? '').toString(),
      stoppageCount: _toInt(json['stoppageCount'] ?? json['stoppage_count'] ?? 0),
      studentCount: _toInt(json['studentCount'] ?? json['student_count'] ??
          (json['attendance'] as List?)?.length ?? 0),
      tripStatus: (json['status'] ?? json['tripStatus'] ?? 'NOT_STARTED').toString(),
      tripType: (json['tripType'] ?? json['trip_type'] ?? 'morning').toString(),
    );
  }

  // From GET /api/driver/route when no trip exists yet
  factory DriverTrip.fromRouteJson(Map<String, dynamic> json) {
    final stoppages = (json['stoppages'] ?? json['stops'] ?? <dynamic>[]) as List;
    int studentCount = 0;
    for (final s in stoppages) {
      final assignments = (s['assignments'] ?? <dynamic>[]) as List;
      studentCount += assignments.length;
    }
    return DriverTrip(
      id: '',
      routeId: (json['id'] ?? '').toString(),
      routeName: (json['name'] ?? '').toString(),
      vehicleNumber: (json['vehicleNumber'] ?? json['vehicle_number'] ?? '').toString(),
      stoppageCount: stoppages.length,
      studentCount: studentCount,
      tripStatus: 'NOT_STARTED',
      tripType: 'morning',
    );
  }

  factory DriverTrip.empty() => const DriverTrip(
        id: '',
        routeId: '',
        routeName: '',
        vehicleNumber: '',
        stoppageCount: 0,
        studentCount: 0,
        tripStatus: 'NOT_STARTED',
        tripType: 'morning',
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class Stoppage {
  const Stoppage({
    required this.id,
    required this.name,
    required this.order,
    required this.studentCount,
  });

  final String id;
  final String name;
  final int order;
  final int studentCount;

  factory Stoppage.fromJson(Map<String, dynamic> json) {
    return Stoppage(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      order: _toInt(json['order'] ?? json['sequence'] ?? 0),
      studentCount: _toInt(json['studentCount'] ?? json['student_count'] ??
          (json['assignments'] as List?)?.length ?? 0),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class DriverRoute {
  const DriverRoute({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    required this.driverName,
    required this.conductorName,
    required this.stoppages,
  });

  final String id;
  final String name;
  final String vehicleNumber;
  final String driverName;
  final String conductorName;
  final List<Stoppage> stoppages;

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    final stops = (json['stoppages'] ?? json['stops'] ?? <dynamic>[]) as List;
    return DriverRoute(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['routeName'] ?? json['route_name'] ?? '').toString(),
      vehicleNumber: (json['vehicleNumber'] ?? json['vehicle_number'] ?? '').toString(),
      driverName: (json['driverName'] ?? json['driver_name'] ?? '').toString(),
      conductorName: (json['conductorName'] ?? json['conductor_name'] ?? '').toString(),
      stoppages: stops
          .map((s) => Stoppage.fromJson(s as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  factory DriverRoute.empty() => const DriverRoute(
        id: '',
        name: '',
        vehicleNumber: '',
        driverName: '',
        conductorName: '',
        stoppages: [],
      );
}

class DriverStudent {
  DriverStudent({
    required this.id,
    required this.attendanceId,
    required this.name,
    required this.className,
    required this.section,
    required this.stoppageName,
    required this.parentPhone,
    required this.status,
  });

  final String id;
  final String attendanceId; // busTripAttendance.id for PUT payload
  final String name;
  final String className;
  final String section;
  final String stoppageName;
  final String parentPhone;
  String status; // 'PRESENT' | 'ABSENT' | 'NOT_BOARDED'

  // From trip attendance response: { id, status, student: {...}, stoppage: {...} }
  factory DriverStudent.fromTripAttendanceJson(Map<String, dynamic> json) {
    final stu = (json['student'] ?? const {}) as Map<String, dynamic>;
    final stop = (json['stoppage'] ?? const {}) as Map<String, dynamic>;
    return DriverStudent(
      id: (stu['id'] ?? '').toString(),
      attendanceId: (json['id'] ?? '').toString(),
      name: '${stu['firstName'] ?? ''} ${stu['lastName'] ?? ''}'.trim(),
      className: (stu['class'] is Map ? stu['class']['name'] : stu['class'] ?? '').toString(),
      section: (stu['section'] is Map ? stu['section']['name'] : stu['section'] ?? '').toString(),
      stoppageName: (stop['name'] ?? '').toString(),
      parentPhone: (stu['parentPhone'] ?? stu['phone'] ?? '').toString(),
      status: (json['status'] ?? 'PRESENT').toString(),
    );
  }

  // From route stoppages → assignments → student
  factory DriverStudent.fromRouteJson(Map<String, dynamic> stu, String stopName) {
    return DriverStudent(
      id: (stu['id'] ?? '').toString(),
      attendanceId: '',
      name: '${stu['firstName'] ?? ''} ${stu['lastName'] ?? ''}'.trim(),
      className: (stu['class'] is Map ? stu['class']['name'] : stu['class'] ?? '').toString(),
      section: (stu['section'] is Map ? stu['section']['name'] : stu['section'] ?? '').toString(),
      stoppageName: stopName,
      parentPhone: (stu['parentPhone'] ?? stu['phone'] ?? '').toString(),
      status: 'PRESENT',
    );
  }

  // Payload for PUT /api/driver/trips/{id}/attendance
  Map<String, dynamic> toJson() => {
        'id': attendanceId,
        'status': status.toUpperCase(),
      };
}
