// Approval card models for the unified admin Approvals screen.
//
// Three flows from the Next.js backend:
//   • Visitor gate passes   — /api/admin/gate-passes
//   • Permanent gate passes — /api/admin/gate-passes/permanent
//   • Staff leave requests  — /api/admin/attendance/leaves

class GatePassApproval {
  const GatePassApproval({
    required this.id,
    required this.passType,
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
  });

  final String id;
  final String passType;
  final String title;
  final String subtitle;
  final String reason;
  final String validFrom;
  final String validUntil;
  final String createdAt;

  factory GatePassApproval.fromJson(Map<String, dynamic> json) {
    final visitor = json['visitor'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    String title = 'Gate Pass';
    String subtitle = '';
    if (visitor != null) {
      title = (visitor['fullName'] ?? '').toString();
      subtitle = (visitor['phone'] ?? '').toString();
    } else if (student != null) {
      title = '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
      subtitle = 'Adm# ${student['admissionNumber'] ?? ''}';
    }
    return GatePassApproval(
      id:         (json['id'] ?? '').toString(),
      passType:   (json['passType'] ?? '').toString(),
      title:      title.isNotEmpty ? title : 'Pass',
      subtitle:   subtitle,
      reason:     (json['reason'] ?? '').toString(),
      validFrom:  (json['validFrom'] ?? '').toString(),
      validUntil: (json['validUntil'] ?? '').toString(),
      createdAt:  (json['createdAt'] ?? '').toString(),
    );
  }
}

class PermanentPassApproval {
  const PermanentPassApproval({
    required this.id,
    required this.visitorName,
    required this.visitorPhone,
    required this.purpose,
    required this.validFrom,
    required this.validUntil,
  });

  final String id;
  final String visitorName;
  final String visitorPhone;
  final String purpose;
  final String validFrom;
  final String? validUntil;

  factory PermanentPassApproval.fromJson(Map<String, dynamic> json) {
    return PermanentPassApproval(
      id:           (json['id'] ?? '').toString(),
      visitorName:  (json['visitorName'] ?? '').toString(),
      visitorPhone: (json['visitorPhone'] ?? '').toString(),
      purpose:      (json['purpose'] ?? '').toString(),
      validFrom:    (json['validFrom'] ?? '').toString(),
      validUntil:   json['validUntil']?.toString(),
    );
  }
}

class LeaveApproval {
  const LeaveApproval({
    required this.id,
    required this.staffName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.daysCount,
  });

  final String id;
  final String staffName;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String reason;
  final int daysCount;

  factory LeaveApproval.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return LeaveApproval(
      id:        (json['id'] ?? '').toString(),
      staffName: (user?['name'] ?? json['staffName'] ?? '').toString(),
      leaveType: (json['leaveType'] ?? '').toString(),
      fromDate:  (json['fromDate'] ?? '').toString(),
      toDate:    (json['toDate'] ?? '').toString(),
      reason:    (json['reason'] ?? '').toString(),
      daysCount: (json['daysCount'] is num)
          ? (json['daysCount'] as num).toInt()
          : 1,
    );
  }
}
