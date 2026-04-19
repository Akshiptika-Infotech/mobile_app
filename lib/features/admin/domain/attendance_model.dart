// ── Face Scan ─────────────────────────────────────────────────────────────────

class FaceScanParams {
  const FaceScanParams({
    required this.classId,
    required this.className,
    required this.academicYearId,
    required this.date,
    required this.attendanceType,
    this.sectionId,
    this.sectionName,
  });

  final String classId;
  final String className;
  final String academicYearId;
  final String date; // "YYYY-MM-DD"
  final String attendanceType; // e.g. "MORNING" | "AFTERNOON"
  final String? sectionId;
  final String? sectionName;
}

// ── QR Scan ───────────────────────────────────────────────────────────────────

class QrScanParams {
  const QrScanParams({
    required this.classId,
    required this.className,
    required this.academicYearId,
    required this.date,
    this.sectionId,
    this.sectionName,
  });

  final String classId;
  final String className;
  final String academicYearId;
  final String date; // "YYYY-MM-DD"
  final String? sectionId;
  final String? sectionName;
}

class QrScanResult {
  const QrScanResult({
    required this.ok,
    required this.type,
    required this.name,
    required this.status,
    this.admissionNumber,
  });

  final bool ok;
  final String type; // 'student' | 'staff'
  final String name;
  final String status;
  final String? admissionNumber;

  factory QrScanResult.fromJson(Map<String, dynamic> json) => QrScanResult(
        ok: json['ok'] == true,
        type: (json['type'] ?? 'student').toString(),
        name: (json['name'] ?? '').toString(),
        status: (json['status'] ?? 'PRESENT').toString(),
        admissionNumber: json['admissionNumber']?.toString(),
      );
}

class LiveAttendanceStudent {
  const LiveAttendanceStudent({
    required this.id,
    required this.admissionNumber,
    required this.name,
    this.photoPath,
    this.attendanceStatus,
    this.attendanceId,
  });

  final String id;
  final String admissionNumber;
  final String name;
  final String? photoPath;
  final String? attendanceStatus; // null = not marked yet
  final String? attendanceId;

  bool get isMarked => attendanceStatus != null;
  bool get isPresent => attendanceStatus == 'PRESENT';

  factory LiveAttendanceStudent.fromJson(Map<String, dynamic> json) {
    final att = json['attendance'] as Map<String, dynamic>?;
    return LiveAttendanceStudent(
      id: (json['id'] ?? '').toString(),
      admissionNumber: (json['admissionNumber'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      photoPath: json['photoPath']?.toString(),
      attendanceStatus: att?['status']?.toString(),
      attendanceId: att?['id']?.toString(),
    );
  }
}

// ── QR helper ────────────────────────────────────────────────────────────────

class QrPayload {
  const QrPayload({required this.type, required this.identifier});

  final String type; // 'student' | 'staff'
  final String identifier;

  static QrPayload? parse(String raw) {
    if (raw.startsWith('SICS-S:')) {
      return QrPayload(type: 'student', identifier: raw.substring(7).trim());
    }
    if (raw.startsWith('SICS-T:')) {
      return QrPayload(type: 'staff', identifier: raw.substring(7).trim());
    }
    return null;
  }
}

class AttendanceStudent {
  AttendanceStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.admissionNumber,
    required this.status,
    this.photoPath,
    this.attendanceId,
  });

  final String id;
  final String name;
  final String rollNumber;
  final String admissionNumber;
  final String? photoPath;
  final String? attendanceId; // non-null means server already has a record
  String status; // 'present' | 'absent' | 'late'

  bool get isServerMarked => attendanceId != null;

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    // Handle both flat { id, name, status } and nested { student: {...}, attendance: {...} }
    final student = json['student'] as Map<String, dynamic>? ?? json;
    final att = json['attendance'] as Map<String, dynamic>?;

    // Status: only trust server status if attendance record exists
    // Valid values match StudentAttendanceStatus enum: PRESENT | ABSENT | LEAVE | MEDICAL
    const validStatuses = {'present', 'absent', 'leave', 'medical'};
    String status = 'present'; // UI default for unmarked
    if (att != null && att['status'] != null) {
      final raw = att['status'].toString().toLowerCase();
      if (validStatuses.contains(raw)) status = raw;
    } else if (json['status'] != null && att == null) {
      final raw = json['status'].toString().toLowerCase();
      if (validStatuses.contains(raw)) status = raw;
    }

    return AttendanceStudent(
      id: (student['id'] ?? json['id'] ?? '').toString(),
      name: _pickName(student, json),
      rollNumber: (student['rollNumber'] ??
              student['roll_number'] ??
              json['rollNumber'] ??
              json['roll_number'] ??
              '')
          .toString(),
      admissionNumber: (student['admissionNumber'] ??
              student['admission_number'] ??
              json['admissionNumber'] ??
              json['admission_number'] ??
              '')
          .toString(),
      photoPath: (student['photoPath'] ?? student['photo'] ?? json['photoPath'])
          ?.toString(),
      attendanceId: att?['id']?.toString(),
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': id,
        'status': status,
      };

  static String _pickName(
      Map<String, dynamic> student, Map<String, dynamic> json) {
    // 1. Try direct 'name' key on either map
    for (final m in [student, json]) {
      final v = m['name'];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    // 2. Try common alias keys
    for (final key in ['studentName', 'student_name', 'fullName', 'full_name']) {
      final v = student[key] ?? json[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    // 3. Compose from firstName [middleName] lastName (same as StudentModel)
    for (final m in [student, json]) {
      final first  = (m['firstName']  ?? m['first_name']  ?? '').toString().trim();
      final middle = (m['middleName'] ?? m['middle_name'] ?? '').toString().trim();
      final last   = (m['lastName']   ?? m['last_name']   ?? '').toString().trim();
      final parts  = [first, middle, last].where((p) => p.isNotEmpty);
      if (parts.isNotEmpty) return parts.join(' ');
    }
    return '';
  }
}

class MyClassAttendanceResponse {
  const MyClassAttendanceResponse({
    required this.students,
    this.classId,
    this.academicYearId,
    this.sectionId,
    this.locked = false,
  });

  final List<AttendanceStudent> students;
  final String? classId;
  final String? academicYearId;
  final String? sectionId;
  final bool locked;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
  });

  final String studentId;
  final String studentName;
  final String date;
  final String status;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId:
          (json['studentId'] ?? json['student_id'] ?? '').toString(),
      studentName:
          (json['studentName'] ?? json['student_name'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class MyAttendanceSummary {
  const MyAttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.recent,
  });

  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final List<AttendanceRecord> recent;

  factory MyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final recentList =
        (json['recent'] ?? json['records'] ?? <dynamic>[]) as List;
    // API returns nested summary object: { records: [...], summary: { present, absent, late, halfDay, leave, total } }
    final summary = json['summary'] as Map<String, dynamic>?;
    return MyAttendanceSummary(
      totalDays: _toInt(summary?['total'] ?? json['totalDays'] ?? json['total_days'] ?? 0),
      presentDays:
          _toInt(summary?['present'] ?? json['presentDays'] ?? json['present_days'] ?? 0),
      absentDays:
          _toInt(summary?['absent'] ?? json['absentDays'] ?? json['absent_days'] ?? 0),
      lateDays: _toInt(summary?['late'] ?? json['lateDays'] ?? json['late_days'] ?? 0),
      recent: recentList
          .map((e) =>
              AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
