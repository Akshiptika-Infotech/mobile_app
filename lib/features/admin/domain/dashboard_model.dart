class Defaulter {
  const Defaulter({
    required this.id,
    required this.name,
    required this.className,
    required this.amountDue,
    this.section,
    this.photo,
  });

  final String id;
  final String name;
  final String className;
  final double amountDue;
  final String? section;
  final String? photo;

  String get classDisplay => [
        className,
        if (section != null && section!.isNotEmpty) section!,
      ].join(' - ');

  factory Defaulter.fromJson(Map<String, dynamic> json) {
    // Some APIs nest student details under a 'student' key
    final nested = json['student'] as Map<String, dynamic>?;

    // Student name — assemble from parts or fall back to whole-name fields
    final String name;
    final firstName = (json['first_name'] ?? nested?['first_name'] ?? '').toString().trim();
    final middleName = (json['middle_name'] ?? nested?['middle_name'] ?? '').toString().trim();
    final lastName = (json['last_name'] ?? nested?['last_name'] ?? '').toString().trim();
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      name = [firstName, if (middleName.isNotEmpty) middleName, lastName]
          .where((p) => p.isNotEmpty)
          .join(' ');
    } else {
      name = (json['name'] ??
              nested?['name'] ??
              json['studentName'] ??
              json['fullName'] ??
              json['student_name'] ??
              json['full_name'] ??
              json['displayName'] ??
              '')
          .toString()
          .trim();
    }

    // Class/grade — try multiple field names (flat and nested)
    final className = (json['class'] ??
            nested?['class'] ??
            json['className'] ??
            nested?['className'] ??
            json['class_name'] ??
            json['grade'] ??
            '')
        .toString();

    // Section
    final sectionRaw = (json['section'] ??
            nested?['section'] ??
            json['sectionName'] ??
            json['section_name'])
        ?.toString()
        .trim();
    final section = (sectionRaw?.isNotEmpty == true) ? sectionRaw : null;

    // Amount due — try multiple field names
    final amountDue = _toDouble(json['amountDue'] ??
        json['amount_due'] ??
        json['totalDue'] ??
        json['total_due'] ??
        json['dueAmount'] ??
        json['due_amount'] ??
        json['outstanding'] ??
        json['balance'] ??
        json['pendingAmount'] ??
        json['pending_amount'] ??
        0);

    final photo = (json['photo'] ??
            nested?['photo'] ??
            json['image'] ??
            nested?['image'] ??
            json['profileImage'] ??
            json['profile_image'] ??
            json['photoUrl'] ??
            json['photo_url'] ??
            json['avatar'] ??
            nested?['avatar'])
        ?.toString();

    return Defaulter(
      id: (json['id'] ?? nested?['id'] ?? json['studentId'] ?? '').toString(),
      name: name,
      className: className,
      amountDue: amountDue,
      section: section,
      photo: (photo?.isNotEmpty == true) ? photo : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class DashboardStats {
  const DashboardStats({
    required this.todayCollection,
    required this.monthlyTotal,
    required this.activeStudents,
    required this.staffCount,
    required this.topDefaulters,
  });

  final double todayCollection;
  final double monthlyTotal;
  final int activeStudents;
  final int staffCount;
  final List<Defaulter> topDefaulters;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final defaultersList = (json['topDefaulters'] ??
            json['top_defaulters'] ??
            json['defaulters'] ??
            json['feeDefaulters'] ??
            json['fee_defaulters'] ??
            <dynamic>[]) as List<dynamic>;
    return DashboardStats(
      todayCollection:
          _toDouble(json['todayCollection'] ?? json['today_collection'] ?? 0),
      monthlyTotal:
          _toDouble(json['monthlyTotal'] ?? json['monthly_total'] ?? 0),
      activeStudents:
          _toInt(json['activeStudents'] ?? json['active_students'] ?? 0),
      staffCount: _toInt(json['staffCount'] ?? json['staff_count'] ??
          json['totalStaff'] ?? json['totalTeachers'] ??
          json['employeeCount'] ?? json['userCount'] ?? 0),
      topDefaulters: defaultersList
          .map((e) => Defaulter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
