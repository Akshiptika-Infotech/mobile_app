import 'package:mobile_app/features/security/domain/security_enums.dart';

/// Gate pass as returned by `GET /api/security/gate-passes`. Includes the
/// related visitor / student so the row can render the person's name
/// without extra requests.
class GatePass {
  const GatePass({
    required this.id,
    required this.passType,
    required this.status,
    required this.reason,
    required this.validFrom,
    required this.validUntil,
    this.visitorName,
    this.visitorPhone,
    this.studentName,
    this.studentAdmissionNumber,
    this.createdByName,
    this.approvedByName,
  });

  final String id;
  final PassType passType;
  final GatePassStatus status;
  final String reason;
  final DateTime validFrom;
  final DateTime validUntil;
  final String? visitorName;
  final String? visitorPhone;
  final String? studentName;
  final String? studentAdmissionNumber;
  final String? createdByName;
  final String? approvedByName;

  /// Human-readable label for the cell title.
  String get personName {
    if (visitorName != null && visitorName!.isNotEmpty) return visitorName!;
    if (studentName != null && studentName!.isNotEmpty) return studentName!;
    return 'Unknown';
  }

  factory GatePass.fromJson(Map<String, dynamic> json) {
    final visitor = json['visitor'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    final approvedBy = json['approvedBy'] as Map<String, dynamic>?;

    String? studentDisplay;
    if (student != null) {
      final first = (student['firstName'] ?? '').toString();
      final last = (student['lastName'] ?? '').toString();
      final n = '$first $last'.trim();
      studentDisplay = n.isEmpty ? null : n;
    }

    return GatePass(
      id: (json['id'] ?? '').toString(),
      passType: PassType.parse(json['passType']?.toString()),
      status: GatePassStatus.parse(json['status']?.toString()),
      reason: (json['reason'] ?? '').toString(),
      validFrom: DateTime.tryParse(json['validFrom']?.toString() ?? '') ??
          DateTime.now(),
      validUntil: DateTime.tryParse(json['validUntil']?.toString() ?? '') ??
          DateTime.now(),
      visitorName: visitor?['fullName']?.toString(),
      visitorPhone: visitor?['phone']?.toString(),
      studentName: studentDisplay,
      studentAdmissionNumber: student?['admissionNumber']?.toString(),
      createdByName: createdBy?['name']?.toString(),
      approvedByName: approvedBy?['name']?.toString(),
    );
  }
}
