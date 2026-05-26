import 'package:mobile_app/features/security/domain/security_enums.dart';

/// Entry/exit log row from `GET /api/security/entry-exit`.
class EntryExitLog {
  const EntryExitLog({
    required this.id,
    required this.logType,
    required this.personType,
    required this.loggedAt,
    this.notes,
    this.personName,
    this.personDetail,
    this.loggedByName,
  });

  final String id;
  final LogType logType;
  final PersonType personType;
  final DateTime loggedAt;
  final String? notes;

  /// Display name: student/staff/visitor name depending on personType.
  final String? personName;

  /// Secondary info: admission #, role, or phone (best-effort).
  final String? personDetail;

  /// Name of the guard who created the entry.
  final String? loggedByName;

  factory EntryExitLog.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final staff = json['staff'] as Map<String, dynamic>?;
    final visitor = json['visitor'] as Map<String, dynamic>?;
    final loggedBy = json['loggedBy'] as Map<String, dynamic>?;

    String? name;
    String? detail;

    if (student != null) {
      final first = (student['firstName'] ?? '').toString();
      final last = (student['lastName'] ?? '').toString();
      name = '$first $last'.trim();
      detail = student['admissionNumber']?.toString();
    } else if (staff != null) {
      name = staff['name']?.toString();
      detail = staff['role']?.toString();
    } else if (visitor != null) {
      name = visitor['fullName']?.toString();
      detail = visitor['phone']?.toString();
    }

    return EntryExitLog(
      id: (json['id'] ?? '').toString(),
      logType: LogType.parse(json['logType']?.toString()),
      personType: PersonType.parse(json['personType']?.toString()),
      loggedAt: DateTime.tryParse(json['loggedAt']?.toString() ?? '') ??
          DateTime.now(),
      notes: json['notes']?.toString(),
      personName: name,
      personDetail: detail,
      loggedByName: loggedBy?['name']?.toString(),
    );
  }
}

/// Payload for `POST /api/security/entry-exit`. At least one of
/// [studentId] / [staffId] / [visitorId] should be supplied; the server
/// uses [personType] to know which one is canonical. [gatePassId] is
/// optional — when present, the matching pass auto-marks USED.
class EntryExitPayload {
  const EntryExitPayload({
    required this.logType,
    required this.personType,
    this.studentId,
    this.staffId,
    this.visitorId,
    this.gatePassId,
    this.notes,
  });

  final LogType logType;
  final PersonType personType;
  final String? studentId;
  final String? staffId;
  final String? visitorId;
  final String? gatePassId;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'logType': logType.apiValue,
        'personType': personType.apiValue,
        if (studentId != null) 'studentId': studentId,
        if (staffId != null) 'staffId': staffId,
        if (visitorId != null) 'visitorId': visitorId,
        if (gatePassId != null) 'gatePassId': gatePassId,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
