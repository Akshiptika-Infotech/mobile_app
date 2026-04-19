class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? employeeId;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // NextAuth session shape: { user: { id, name, email, role, employeeId } }
    final user =
        json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;

    return UserModel(
      id: (user['id'] ?? '').toString(),
      name: (user['name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      role: (user['role'] ?? '').toString().toUpperCase(),
      employeeId: user['employeeId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (employeeId != null) 'employeeId': employeeId,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? employeeId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, role: $role)';
}

/// All supported role strings returned by the API.
class AppRole {
  AppRole._();

  static const superAdmin = 'SUPER_ADMIN';
  static const admin = 'ADMIN';
  static const clerk = 'CLERK';
  static const teacher = 'TEACHER';
  static const driver = 'DRIVER';
  static const securityGuard = 'SECURITY_GUARD';
  static const receptionist = 'RECEPTIONIST';
  static const student = 'STUDENT';
  static const parent = 'PARENT';
  static const webAdmin = 'WEB_ADMIN';

  static const adminRoles = {superAdmin, admin, clerk, teacher};
}
