/// Server-side enums mirrored for the security portal. Mirrors the Prisma
/// definitions in [d:/Sites/jmukhisics/prisma/schema.prisma].
enum LogType {
  entry('ENTRY', 'Entry'),
  exit('EXIT', 'Exit');

  const LogType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static LogType parse(String? raw) {
    final v = raw?.toUpperCase();
    return LogType.values.firstWhere(
      (e) => e.apiValue == v,
      orElse: () => LogType.entry,
    );
  }
}

enum PersonType {
  student('STUDENT', 'Student'),
  staff('STAFF', 'Staff'),
  visitor('VISITOR', 'Visitor'),
  driver('DRIVER', 'Driver');

  const PersonType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PersonType parse(String? raw) {
    final v = raw?.toUpperCase();
    return PersonType.values.firstWhere(
      (e) => e.apiValue == v,
      orElse: () => PersonType.visitor,
    );
  }
}

enum PassType {
  visitor('VISITOR', 'Visitor'),
  studentOut('STUDENT_OUT', 'Student out'),
  staffOut('STAFF_OUT', 'Staff out');

  const PassType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PassType parse(String? raw) {
    final v = raw?.toUpperCase();
    return PassType.values.firstWhere(
      (e) => e.apiValue == v,
      orElse: () => PassType.visitor,
    );
  }
}

enum GatePassStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  used('USED'),
  expired('EXPIRED');

  const GatePassStatus(this.apiValue);
  final String apiValue;

  static GatePassStatus parse(String? raw) {
    final v = raw?.toUpperCase();
    return GatePassStatus.values.firstWhere(
      (e) => e.apiValue == v,
      orElse: () => GatePassStatus.pending,
    );
  }
}
