/// Driver's assigned route — returned by `GET /api/driver/route`.
class DriverRoute {
  const DriverRoute({
    required this.id,
    required this.name,
    this.description,
    this.driverName,
    this.driverContact,
    this.conductorName,
    this.conductorContact,
    required this.stoppages,
  });

  final String id;
  final String name;
  final String? description;
  final String? driverName;
  final String? driverContact;
  final String? conductorName;
  final String? conductorContact;
  final List<DriverStoppage> stoppages;

  int get totalStudents =>
      stoppages.fold(0, (sum, s) => sum + s.students.length);

  factory DriverRoute.fromJson(Map<String, dynamic> json) {
    final stoppageList = (json['stoppages'] as List? ?? const []);
    return DriverRoute(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      driverName: json['driverName']?.toString(),
      driverContact: json['driverContact']?.toString(),
      conductorName: json['conductorName']?.toString(),
      conductorContact: json['conductorContact']?.toString(),
      stoppages: stoppageList
          .map((s) => DriverStoppage.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DriverStoppage {
  const DriverStoppage({
    required this.id,
    required this.name,
    required this.order,
    required this.feeAmount,
    required this.students,
  });

  final String id;
  final String name;
  final int order;
  final double feeAmount;
  final List<DriverRouteStudent> students;

  factory DriverStoppage.fromJson(Map<String, dynamic> json) {
    final assignments = (json['assignments'] as List? ?? const []);
    return DriverStoppage(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      feeAmount: _toDouble(json['feeAmount']),
      students: assignments
          .map((a) {
            final student = (a as Map<String, dynamic>)['student']
                as Map<String, dynamic>?;
            if (student == null) return null;
            return DriverRouteStudent.fromJson(student);
          })
          .whereType<DriverRouteStudent>()
          .toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class DriverRouteStudent {
  const DriverRouteStudent({
    required this.id,
    required this.name,
    required this.admissionNumber,
    this.photoUrl,
    this.className,
    this.section,
  });

  final String id;
  final String name;
  final String admissionNumber;
  final String? photoUrl;
  final String? className;
  final String? section;

  factory DriverRouteStudent.fromJson(Map<String, dynamic> json) {
    final first = (json['firstName'] ?? '').toString();
    final last = (json['lastName'] ?? '').toString();
    final name = '$first $last'.trim();
    final cls = json['class'];
    final sec = json['section'];
    return DriverRouteStudent(
      id: (json['id'] ?? '').toString(),
      name: name.isNotEmpty ? name : (json['name'] ?? '').toString(),
      admissionNumber: (json['admissionNumber'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? json['photoPath'])?.toString(),
      className: cls is Map ? cls['name']?.toString() : null,
      section: sec is Map ? sec['name']?.toString() : null,
    );
  }
}
