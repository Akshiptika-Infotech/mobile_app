/// A child returned by `GET /api/parent/children`.
class ParentChild {
  const ParentChild({
    required this.id,
    required this.name,
    required this.admissionNumber,
    this.className,
    this.section,
    this.photoPath,
    this.academicYearId,
  });

  final String id;
  final String name;
  final String admissionNumber;
  final String? className;
  final String? section;
  final String? photoPath;
  final String? academicYearId;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory ParentChild.fromJson(Map<String, dynamic> json) {
    final first = (json['firstName'] ?? '').toString();
    final last = (json['lastName'] ?? '').toString();
    final fallback = (json['name'] ?? '').toString();
    final cls = json['class'];
    final sec = json['section'];
    return ParentChild(
      id: (json['id'] ?? '').toString(),
      name: ('$first $last').trim().isNotEmpty
          ? '$first $last'.trim()
          : fallback,
      admissionNumber: (json['admissionNumber'] ?? '').toString(),
      className: cls is Map ? cls['name']?.toString() : null,
      section: sec is Map ? sec['name']?.toString() : null,
      photoPath: (json['photoPath'] ?? json['photoUrl'])?.toString(),
      academicYearId:
          (json['academicYearId'] ?? json['academic_year_id'])?.toString(),
    );
  }
}
