class StaffUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? image;
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
    this.image,
    this.employeeId,
    this.phone,
    this.assignedClass,
    this.assignedSection,
    required this.isActive,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    final assignedClassRaw = json['assignedClass'];
    final assignedSectionRaw = json['assignedSection'];
    final assignedClass = assignedClassRaw is Map<String, dynamic>
        ? assignedClassRaw['name']?.toString()
        : assignedClassRaw?.toString();
    final assignedSection = assignedSectionRaw is Map<String, dynamic>
        ? assignedSectionRaw['name']?.toString()
        : assignedSectionRaw?.toString();
    return StaffUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      image: json['image']?.toString(),
      employeeId: json['employeeId']?.toString(),
      phone: json['phone']?.toString(),
      assignedClass: assignedClass,
      assignedSection: assignedSection,
      isActive: json['isActive'] == true || json['hasLogin'] == true,
    );
  }
}
