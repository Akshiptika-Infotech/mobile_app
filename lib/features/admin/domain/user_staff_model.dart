class StaffUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? employeeId;
  final String? phone;
  final String? assignedClass;
  final String? assignedSection;
  final bool isActive;

  const StaffUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
    this.phone,
    this.assignedClass,
    this.assignedSection,
    required this.isActive,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) => StaffUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        employeeId: json['employeeId']?.toString(),
        phone: json['phone']?.toString(),
        assignedClass: json['assignedClass']?.toString(),
        assignedSection: json['assignedSection']?.toString(),
        isActive: json['isActive'] == true,
      );
}
