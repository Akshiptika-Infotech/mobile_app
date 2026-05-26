import 'package:mobile_app/features/security/domain/security_enums.dart';

/// Visitor as returned by `GET /api/security/visitors`. Includes the latest
/// approved gate pass and the most recent entry/exit log so the list cell
/// can render status without further fetches.
class SecurityVisitor {
  const SecurityVisitor({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.purposeOfVisit,
    this.personToMeet,
    this.vehicleNumber,
    this.imagePath,
    required this.createdAt,
    this.latestPass,
    this.latestLog,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String purposeOfVisit;
  final String? personToMeet;
  final String? vehicleNumber;
  final String? imagePath;
  final DateTime createdAt;
  final VisitorPassSummary? latestPass;
  final VisitorLogSummary? latestLog;

  /// True when the visitor is currently inside (last log was ENTRY).
  bool get isInside => latestLog?.logType == LogType.entry;

  factory SecurityVisitor.fromJson(Map<String, dynamic> json) {
    final passes = json['gatePasses'] as List? ?? const [];
    final logs = json['entryExitLogs'] as List? ?? const [];
    return SecurityVisitor(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      purposeOfVisit: (json['purposeOfVisit'] ?? '').toString(),
      personToMeet: json['personToMeet']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      imagePath: json['imagePath']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      latestPass: passes.isNotEmpty
          ? VisitorPassSummary.fromJson(passes.first as Map<String, dynamic>)
          : null,
      latestLog: logs.isNotEmpty
          ? VisitorLogSummary.fromJson(logs.first as Map<String, dynamic>)
          : null,
    );
  }
}

class VisitorPassSummary {
  const VisitorPassSummary({
    required this.id,
    required this.status,
    this.validFrom,
    this.validUntil,
  });

  final String id;
  final GatePassStatus status;
  final DateTime? validFrom;
  final DateTime? validUntil;

  factory VisitorPassSummary.fromJson(Map<String, dynamic> json) =>
      VisitorPassSummary(
        id: (json['id'] ?? '').toString(),
        status: GatePassStatus.parse(json['status']?.toString()),
        validFrom: DateTime.tryParse(json['validFrom']?.toString() ?? ''),
        validUntil: DateTime.tryParse(json['validUntil']?.toString() ?? ''),
      );
}

class VisitorLogSummary {
  const VisitorLogSummary({
    required this.id,
    required this.logType,
    required this.loggedAt,
  });

  final String id;
  final LogType logType;
  final DateTime loggedAt;

  factory VisitorLogSummary.fromJson(Map<String, dynamic> json) =>
      VisitorLogSummary(
        id: (json['id'] ?? '').toString(),
        logType: LogType.parse(json['logType']?.toString()),
        loggedAt: DateTime.tryParse(json['loggedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// Payload for `POST /api/security/visitors`.
class RegisterVisitorPayload {
  const RegisterVisitorPayload({
    required this.fullName,
    required this.phone,
    this.email,
    required this.purposeOfVisit,
    required this.personToMeet,
    this.vehicleNumber,
    this.imagePath,
    this.validHours = 8,
  });

  final String fullName;
  final String phone;
  final String? email;
  final String purposeOfVisit;
  final String personToMeet;
  final String? vehicleNumber;
  final String? imagePath;
  final int validHours;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        'purposeOfVisit': purposeOfVisit,
        'personToMeet': personToMeet,
        if (vehicleNumber != null && vehicleNumber!.isNotEmpty)
          'vehicleNumber': vehicleNumber,
        if (imagePath != null && imagePath!.isNotEmpty) 'imagePath': imagePath,
        'validHours': validHours,
      };
}
