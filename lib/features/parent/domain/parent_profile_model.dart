/// Parent profile — `GET /api/parent/profile` returns
/// `{user: {...}, parent: {father*, mother*}}`.
class ParentProfile {
  const ParentProfile({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.fatherName,
    this.fatherContact,
    this.fatherEmail,
    this.fatherOccupation,
    this.fatherAddress,
    this.motherName,
    this.motherContact,
    this.motherEmail,
    this.motherOccupation,
    this.motherAddress,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final String? fatherName;
  final String? fatherContact;
  final String? fatherEmail;
  final String? fatherOccupation;
  final String? fatherAddress;
  final String? motherName;
  final String? motherContact;
  final String? motherEmail;
  final String? motherOccupation;
  final String? motherAddress;

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final parent =
        (json['parent'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ParentProfile(
      userId: (user['id'] ?? '').toString(),
      userName: (user['name'] ?? '').toString(),
      userEmail: (user['email'] ?? '').toString(),
      fatherName: parent['fatherName']?.toString(),
      fatherContact: parent['fatherContact']?.toString(),
      fatherEmail: parent['fatherEmail']?.toString(),
      fatherOccupation: parent['fatherOccupation']?.toString(),
      fatherAddress: parent['fatherAddress']?.toString(),
      motherName: parent['motherName']?.toString(),
      motherContact: parent['motherContact']?.toString(),
      motherEmail: parent['motherEmail']?.toString(),
      motherOccupation: parent['motherOccupation']?.toString(),
      motherAddress: parent['motherAddress']?.toString(),
    );
  }
}
