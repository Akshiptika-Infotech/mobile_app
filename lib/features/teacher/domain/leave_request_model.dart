/// A staff leave request as returned by `/api/admin/attendance/leaves`.
class LeaveRequestModel {
  const LeaveRequestModel({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.leaveType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewerNote,
  });

  final String id;
  final DateTime fromDate;
  final DateTime toDate;
  final String leaveType;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewerNote;

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime parse(String? raw, [DateTime? fallback]) {
      if (raw == null || raw.isEmpty) return fallback ?? DateTime.now();
      return DateTime.tryParse(raw) ?? (fallback ?? DateTime.now());
    }

    return LeaveRequestModel(
      id: (json['id'] ?? '').toString(),
      fromDate: parse(json['fromDate']?.toString()),
      toDate: parse(json['toDate']?.toString()),
      leaveType: (json['leaveType'] ?? 'CASUAL').toString(),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: parse(json['createdAt']?.toString()),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      reviewerNote: json['reviewerNote']?.toString(),
    );
  }

  int get totalDays => toDate.difference(fromDate).inDays + 1;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

/// Allowed leave types matching the backend enum.
class LeaveType {
  LeaveType._();

  static const sick = 'SICK';
  static const casual = 'CASUAL';
  static const earned = 'EARNED';
  static const medical = 'MEDICAL';
  static const maternity = 'MATERNITY';

  static const all = [sick, casual, earned, medical, maternity];

  static String label(String type) {
    switch (type.toUpperCase()) {
      case sick:
        return 'Sick Leave';
      case casual:
        return 'Casual Leave';
      case earned:
        return 'Earned Leave';
      case medical:
        return 'Medical Leave';
      case maternity:
        return 'Maternity Leave';
      default:
        return type;
    }
  }
}
