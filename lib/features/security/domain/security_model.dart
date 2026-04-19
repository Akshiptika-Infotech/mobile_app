class SecurityDashboard {
  const SecurityDashboard({
    required this.todayEntries,
    required this.todayExits,
    required this.activeVisitors,
    required this.pendingPasses,
    required this.recentLog,
  });

  final int todayEntries;
  final int todayExits;
  final int activeVisitors;
  final int pendingPasses;
  final List<EntryExitRecord> recentLog;

  factory SecurityDashboard.fromJson(Map<String, dynamic> json) {
    final log = (json['recentLog'] ?? json['recent_log'] ?? json['log'] ?? <dynamic>[]) as List;
    return SecurityDashboard(
      todayEntries: _toInt(json['todayEntries'] ?? json['today_entries'] ?? 0),
      todayExits: _toInt(json['todayExits'] ?? json['today_exits'] ?? 0),
      activeVisitors: _toInt(json['activeVisitors'] ?? json['active_visitors'] ?? 0),
      pendingPasses: _toInt(json['pendingPasses'] ?? json['pending_passes'] ?? 0),
      recentLog: log.map((e) => EntryExitRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class EntryExitRecord {
  const EntryExitRecord({
    required this.id,
    required this.personName,
    required this.personType,
    required this.type,
    required this.time,
    required this.date,
  });

  final String id;
  final String personName;
  final String personType; // 'student' | 'staff' | 'visitor'
  final String type; // 'entry' | 'exit'
  final String time;
  final String date;

  factory EntryExitRecord.fromJson(Map<String, dynamic> json) {
    // Resolve person name from nested objects (actual DB shape)
    String personName = '';
    String personType = 'visitor';
    if (json['student'] != null) {
      final s = json['student'] as Map<String, dynamic>;
      personName = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
      personType = 'student';
    } else if (json['staff'] != null) {
      final st = json['staff'] as Map<String, dynamic>;
      personName = (st['name'] ?? '').toString();
      personType = 'staff';
    } else if (json['visitor'] != null) {
      final v = json['visitor'] as Map<String, dynamic>;
      personName = (v['fullName'] ?? v['name'] ?? '').toString();
      personType = 'visitor';
    } else {
      personName = (json['personName'] ?? json['person_name'] ?? json['name'] ?? '').toString();
      personType = (json['personType'] ?? json['person_type'] ?? 'visitor').toString();
    }

    // Resolve type from logType or type field
    final rawType = (json['logType'] ?? json['type'] ?? 'ENTRY').toString().toLowerCase();
    final type = (rawType == 'exit' || rawType == 'out') ? 'exit' : 'entry';

    // Resolve time from loggedAt or time field
    final loggedAt = json['loggedAt'] ?? json['logged_at'] ?? json['time'] ?? json['date'] ?? '';
    String time = '';
    String date = '';
    if (loggedAt.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(loggedAt.toString()).toLocal();
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        time = loggedAt.toString();
      }
    }

    return EntryExitRecord(
      id: (json['id'] ?? '').toString(),
      personName: personName,
      personType: personType,
      type: type,
      time: time,
      date: date,
    );
  }
}

class Visitor {
  const Visitor({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.purpose,
    required this.personToMeet,
    required this.vehicleNumber,
    this.imagePath,
    required this.passId,
    required this.passStatus,
    required this.validUntil,
    required this.inTime,
    this.outTime,
  });

  final String id;
  final String name;        // fullName
  final String phone;
  final String email;
  final String purpose;     // purposeOfVisit
  final String personToMeet;
  final String vehicleNumber;
  final String? imagePath;
  final String passId;
  final String passStatus;  // APPROVED | USED | EXPIRED
  final String validUntil;
  final String inTime;
  final String? outTime;

  bool get isInside =>
      passStatus.toUpperCase() == 'APPROVED' && outTime == null;

  // From GET /api/security/visitors — includes nested gatePasses[] & entryExitLogs[]
  factory Visitor.fromJson(Map<String, dynamic> json) {
    final passes = (json['gatePasses'] ?? <dynamic>[]) as List;
    final logs = (json['entryExitLogs'] ?? <dynamic>[]) as List;

    // Find the visitor gate pass
    final pass = passes.isNotEmpty ? passes.first as Map<String, dynamic> : <String, dynamic>{};
    final passId = (pass['id'] ?? '').toString();
    final passStatus = (pass['status'] ?? 'APPROVED').toString();
    final validUntil = _fmtTime(pass['validUntil']?.toString() ?? '');

    // Entry time from ENTRY log
    final entryLog = logs.cast<Map<String, dynamic>>().firstWhere(
      (l) => (l['logType'] ?? '').toString().toUpperCase() == 'ENTRY',
      orElse: () => <String, dynamic>{},
    );
    final exitLog = logs.cast<Map<String, dynamic>>().firstWhere(
      (l) => (l['logType'] ?? '').toString().toUpperCase() == 'EXIT',
      orElse: () => <String, dynamic>{},
    );

    return Visitor(
      id: (json['id'] ?? '').toString(),
      name: (json['fullName'] ?? json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      purpose: (json['purposeOfVisit'] ?? json['purpose'] ?? '').toString(),
      personToMeet: (json['personToMeet'] ?? json['hostName'] ?? '').toString(),
      vehicleNumber: (json['vehicleNumber'] ?? '').toString(),
      imagePath: json['imagePath']?.toString(),
      passId: passId,
      passStatus: passStatus,
      validUntil: validUntil,
      inTime: entryLog.isNotEmpty
          ? _fmtTime(entryLog['loggedAt']?.toString() ?? '')
          : _fmtTime(json['createdAt']?.toString() ?? ''),
      outTime: exitLog.isNotEmpty
          ? _fmtTime(exitLog['loggedAt']?.toString() ?? '')
          : null,
    );
  }

  static String _fmtTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class GatePass {
  const GatePass({
    required this.id,
    required this.studentName,
    required this.className,
    required this.section,
    required this.purpose,
    required this.type,
    required this.status,
    required this.validDate,
  });

  final String id;
  final String studentName;
  final String className;
  final String section;
  final String purpose;
  final String type; // 'permanent' | 'temporary'
  final String status; // 'approved' | 'used'
  final String validDate;

  factory GatePass.fromJson(Map<String, dynamic> json) {
    return GatePass(
      id: (json['id'] ?? '').toString(),
      studentName: (json['studentName'] ?? json['student_name'] ?? json['name'] ?? '').toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      purpose: (json['purpose'] ?? '').toString(),
      type: (json['type'] ?? 'temporary').toString(),
      status: (json['status'] ?? 'approved').toString(),
      validDate: (json['validDate'] ?? json['valid_date'] ?? json['date'] ?? '').toString(),
    );
  }
}
