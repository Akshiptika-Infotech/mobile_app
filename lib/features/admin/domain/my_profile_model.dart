class MyProfile {
  const MyProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.assignedClassId,
    this.assignedSectionId,
    this.assignedClassName,
    this.assignedSectionName,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? assignedClassId;
  final String? assignedSectionId;
  final String? assignedClassName;
  final String? assignedSectionName;

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    final assignedClass = json['assignedClass'];
    final assignedSection = json['assignedSection'];
    return MyProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      assignedClassId: json['assignedClassId']?.toString(),
      assignedSectionId: json['assignedSectionId']?.toString(),
      assignedClassName: assignedClass is Map<String, dynamic>
          ? assignedClass['name']?.toString()
          : null,
      assignedSectionName: assignedSection is Map<String, dynamic>
          ? assignedSection['name']?.toString()
          : null,
    );
  }
}
