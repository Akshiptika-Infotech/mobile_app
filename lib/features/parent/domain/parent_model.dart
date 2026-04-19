import 'package:mobile_app/features/student/domain/student_portal_model.dart';

// ── Children ──────────────────────────────────────────────────────────────────

class ChildSummary {
  const ChildSummary({
    required this.id,
    required this.name,
    required this.className,
    required this.section,
    required this.admissionNumber,
  });

  final String id;
  final String name;
  final String className;
  final String section;
  final String admissionNumber;

  factory ChildSummary.fromJson(Map<String, dynamic> json) {
    final firstName = (json['firstName'] ?? '').toString();
    final middleName = (json['middleName'] ?? '').toString();
    final lastName = (json['lastName'] ?? '').toString();
    final nameParts = [firstName, if (middleName.isNotEmpty) middleName, lastName]
        .where((p) => p.isNotEmpty);
    final fullName = nameParts.join(' ').trim();

    final cls = json['class'];
    final sec = json['section'];

    return ChildSummary(
      id: (json['id'] ?? '').toString(),
      name: fullName.isNotEmpty ? fullName : (json['name'] ?? '').toString(),
      className: cls is Map ? (cls['name'] ?? '').toString() : (cls ?? '').toString(),
      section: sec is Map ? (sec['name'] ?? '').toString() : (sec ?? '').toString(),
      admissionNumber: (json['admissionNumber'] ?? '').toString(),
    );
  }
}

// ── Receipts ──────────────────────────────────────────────────────────────────

class ParentReceipt {
  const ParentReceipt({
    required this.id,
    required this.studentName,
    required this.studentClass,
    required this.receiptNumber,
    required this.collectedAt,
    required this.paymentMode,
    required this.status,
    required this.items,
    required this.academicYearName,
    this.isRevoked = false,
  });

  final String id;
  final String studentName;
  final String studentClass;
  final String receiptNumber;
  final String collectedAt;
  final String paymentMode;
  final String status;
  final List<ReceiptItem> items;
  final String academicYearName;
  final bool isRevoked;

  double get total => items.fold(0.0, (s, i) => s + i.amount);

  factory ParentReceipt.fromJson(Map<String, dynamic> json) {
    final s = json['student'] as Map<String, dynamic>? ?? {};
    final firstName = (s['firstName'] ?? '').toString();
    final lastName = (s['lastName'] ?? '').toString();
    final studentCls = s['class'];

    return ParentReceipt(
      id: (json['id'] ?? '').toString(),
      studentName: [firstName, lastName]
          .where((p) => p.isNotEmpty)
          .join(' ')
          .trim(),
      studentClass: studentCls is Map
          ? (studentCls['name'] ?? '').toString()
          : (studentCls ?? '').toString(),
      receiptNumber: (json['receiptNumber'] ?? '').toString(),
      collectedAt: (json['collectedAt'] ?? json['date'] ?? '').toString(),
      paymentMode: (json['paymentMode'] ?? '').toString(),
      status: (json['status'] ?? 'COLLECTED').toString(),
      items: (json['items'] as List? ?? [])
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      academicYearName:
          (json['academicYear'] as Map<String, dynamic>?)?['name']
                  ?.toString() ??
              '',
      isRevoked: json['revocation'] != null,
    );
  }
}

// ── Timetable ─────────────────────────────────────────────────────────────────

class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.subjectName,
    required this.subjectCode,
    required this.teacherName,
  });

  final String id;
  final int dayOfWeek; // 1=Mon … 7=Sun
  final int periodNumber;
  final String subjectName;
  final String subjectCode;
  final String teacherName;

  String get dayLabel {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek.clamp(1, 7)];
  }

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>? ?? {};
    final teacher = json['teacher'] as Map<String, dynamic>? ?? {};
    return TimetableEntry(
      id: (json['id'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      periodNumber: (json['periodNumber'] as num?)?.toInt() ?? 1,
      subjectName: (subject['name'] ?? '').toString(),
      subjectCode: (subject['code'] ?? '').toString(),
      teacherName: (teacher['name'] ?? '').toString(),
    );
  }
}
