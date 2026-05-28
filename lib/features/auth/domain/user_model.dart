class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
    this.image,
    this.expires,
    this.mustChangePassword = false,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? employeeId;
  final String? image;

  /// ISO-8601 expiry timestamp from NextAuth session.
  final DateTime? expires;

  /// Set by the backend when the user was just provisioned (or an admin
  /// reset the password). Router uses this to force the change-password
  /// screen before letting them reach their portal.
  final bool mustChangePassword;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // NextAuth session shape: { user: { id, name, email, role, employeeId, image, mustChangePassword }, expires }
    final user =
        json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;

    final rawImage = user['image']?.toString();
    final expiresRaw = json['expires']?.toString() ?? user['expires']?.toString();
    return UserModel(
      id: (user['id'] ?? '').toString(),
      name: (user['name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      role: (user['role'] ?? '').toString().toUpperCase(),
      employeeId: user['employeeId']?.toString(),
      image: (rawImage == null || rawImage.isEmpty) ? null : rawImage,
      expires: expiresRaw != null ? DateTime.tryParse(expiresRaw) : null,
      mustChangePassword: user['mustChangePassword'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (employeeId != null) 'employeeId': employeeId,
        if (image != null) 'image': image,
        if (expires != null) 'expires': expires!.toIso8601String(),
        if (mustChangePassword) 'mustChangePassword': true,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? employeeId,
    String? image,
    DateTime? expires,
    bool? mustChangePassword,
    bool clearImage = false,
    bool clearExpires = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      image: clearImage ? null : (image ?? this.image),
      expires: clearExpires ? null : (expires ?? this.expires),
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
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

  static const adminRoles = {superAdmin, admin, clerk};
}
