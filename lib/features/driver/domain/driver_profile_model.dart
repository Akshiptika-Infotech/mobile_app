/// Driver profile — `GET /api/driver/profile`.
class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.email,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? imageUrl;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      imageUrl: (json['image'] ?? json['imageUrl'])?.toString(),
    );
  }
}
