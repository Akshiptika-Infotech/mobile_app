/// Security guard profile — `GET /api/security/profile`.
class SecurityProfile {
  const SecurityProfile({
    required this.id,
    required this.name,
    required this.email,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? imageUrl;

  factory SecurityProfile.fromJson(Map<String, dynamic> json) {
    return SecurityProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      imageUrl: (json['image'] ?? json['imageUrl'])?.toString(),
    );
  }
}
