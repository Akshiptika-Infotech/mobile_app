class ReceptionDashboard {
  const ReceptionDashboard({
    required this.todayAppointments,
    required this.pendingPasses,
    required this.callsLogged,
    required this.lateArrivals,
  });

  final int todayAppointments;
  final int pendingPasses;
  final int callsLogged;
  final int lateArrivals;

  factory ReceptionDashboard.fromJson(Map<String, dynamic> json) {
    return ReceptionDashboard(
      todayAppointments: _i(json['todayAppointments'] ?? json['today_appointments'] ?? 0),
      pendingPasses: _i(json['pendingPasses'] ?? json['pending_passes'] ?? 0),
      callsLogged: _i(json['callsLogged'] ?? json['calls_logged'] ?? 0),
      lateArrivals: _i(json['lateArrivals'] ?? json['late_arrivals'] ?? 0),
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class ReceptionVisitor {
  const ReceptionVisitor({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.purposeOfVisit,
    required this.personToMeet,
    required this.date,
  });

  final String id;
  final String fullName;
  final String phone;
  final String purposeOfVisit;
  final String personToMeet;
  final String date;

  factory ReceptionVisitor.fromJson(Map<String, dynamic> json) {
    final raw = json['createdAt'] ?? json['created_at'] ?? json['date'] ?? '';
    String date = '';
    if (raw.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        final months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        date = '${dt.day.toString().padLeft(2,'0')}-${months[dt.month]}';
      } catch (_) {
        date = raw.toString();
      }
    }
    return ReceptionVisitor(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      purposeOfVisit: (json['purposeOfVisit'] ?? json['purpose'] ?? '').toString(),
      personToMeet: (json['personToMeet'] ?? json['hostName'] ?? '').toString(),
      date: date,
    );
  }
}

class ReceptionGatePass {
  const ReceptionGatePass({
    required this.id,
    required this.visitorName,
    required this.purpose,
    required this.hostName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String visitorName;
  final String purpose;
  final String hostName;
  final String status; // 'pending' | 'approved' | 'rejected' | 'used'
  final String createdAt;

  factory ReceptionGatePass.fromJson(Map<String, dynamic> json) {
    return ReceptionGatePass(
      id: (json['id'] ?? '').toString(),
      visitorName: (json['visitorName'] ?? json['visitor_name'] ?? json['name'] ?? '').toString(),
      purpose: (json['purpose'] ?? '').toString(),
      hostName: (json['hostName'] ?? json['host_name'] ?? json['host'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? json['time'] ?? '').toString(),
    );
  }
}

class CallLog {
  const CallLog({
    required this.id,
    required this.callerName,
    required this.phone,
    required this.purpose,
    required this.actionTaken,
    required this.time,
  });

  final String id;
  final String callerName;
  final String phone;
  final String purpose;
  final String actionTaken;
  final String time;

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: (json['id'] ?? '').toString(),
      callerName: (json['callerName'] ?? json['caller_name'] ?? json['name'] ?? '').toString(),
      phone: (json['phone'] ?? json['contact'] ?? '').toString(),
      purpose: (json['purpose'] ?? '').toString(),
      actionTaken: (json['actionTaken'] ?? json['action_taken'] ?? json['action'] ?? '').toString(),
      time: (json['time'] ?? json['createdAt'] ?? json['created_at'] ?? '').toString(),
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.visitorName,
    required this.phone,
    required this.purpose,
    required this.hostName,
    required this.scheduledAt,
    required this.status,
  });

  final String id;
  final String visitorName;
  final String phone;
  final String purpose;
  final String hostName;
  final String scheduledAt;
  final String status; // 'scheduled' | 'completed' | 'cancelled'

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: (json['id'] ?? '').toString(),
      visitorName: (json['visitorName'] ?? json['visitor_name'] ?? json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      purpose: (json['purpose'] ?? '').toString(),
      hostName: (json['hostName'] ?? json['host_name'] ?? json['host'] ?? '').toString(),
      scheduledAt: (json['scheduledAt'] ?? json['scheduled_at'] ?? json['date'] ?? '').toString(),
      status: (json['status'] ?? 'scheduled').toString(),
    );
  }
}

class LateArrival {
  const LateArrival({
    required this.id,
    required this.studentName,
    required this.className,
    required this.section,
    required this.arrivalTime,
    required this.reason,
    required this.notifyParent,
  });

  final String id;
  final String studentName;
  final String className;
  final String section;
  final String arrivalTime;
  final String reason;
  final bool notifyParent;

  factory LateArrival.fromJson(Map<String, dynamic> json) {
    return LateArrival(
      id: (json['id'] ?? '').toString(),
      studentName: (json['studentName'] ?? json['student_name'] ?? json['name'] ?? '').toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      arrivalTime: (json['arrivalTime'] ?? json['arrival_time'] ?? json['time'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      notifyParent: json['notifyParent'] == true || json['notify_parent'] == true,
    );
  }
}
