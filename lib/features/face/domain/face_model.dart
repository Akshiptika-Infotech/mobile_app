class FaceRegisterResult {
  const FaceRegisterResult({
    required this.ok,
    required this.name,
    required this.message,
    this.id,
    this.type,
  });

  final bool ok;
  final String name;
  final String message;
  final String? id;
  final String? type;

  factory FaceRegisterResult.fromJson(Map<String, dynamic> json) =>
      FaceRegisterResult(
        ok: json['ok'] == true,
        name: (json['name'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        id: json['id']?.toString(),
        type: json['type']?.toString(),
      );
}

class FaceVerifyResult {
  const FaceVerifyResult({
    required this.ok,
    required this.matched,
    this.name,
    this.admissionNumber,
    this.similarity,
    this.status,
    this.reason,
    this.type,
  });

  final bool ok;
  final bool matched;
  final String? name;
  final String? admissionNumber;
  final double? similarity;
  final String? status;
  final String? reason;
  final String? type;

  factory FaceVerifyResult.fromJson(Map<String, dynamic> json) =>
      FaceVerifyResult(
        ok: json['ok'] == true,
        matched: json['matched'] == true,
        name: json['name']?.toString(),
        admissionNumber: json['admissionNumber']?.toString(),
        similarity: (json['similarity'] as num?)?.toDouble(),
        status: json['status']?.toString(),
        reason: json['reason']?.toString(),
        type: json['type']?.toString(),
      );
}

class FaceEnrollmentItem {
  const FaceEnrollmentItem({
    required this.id,
    required this.name,
    required this.enrolled,
    this.admissionNumber,
    this.className,
    this.section,
    this.identifier,
  });

  final String id;
  final String name;
  final bool enrolled;
  final String? admissionNumber;
  final String? className;
  final String? section;
  final String? identifier; // for staff

  factory FaceEnrollmentItem.fromJson(Map<String, dynamic> json) =>
      FaceEnrollmentItem(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        enrolled: json['enrolled'] == true,
        admissionNumber: json['admissionNumber']?.toString(),
        className: json['class']?.toString(),
        section: json['section']?.toString(),
        identifier: json['identifier']?.toString(),
      );
}

class FaceEnrollmentList {
  const FaceEnrollmentList({
    required this.items,
    required this.total,
    required this.enrolled,
  });

  final List<FaceEnrollmentItem> items;
  final int total;
  final int enrolled;

  int get pending => total - enrolled;
  double get progress => total == 0 ? 0 : enrolled / total;

  factory FaceEnrollmentList.fromJson(Map<String, dynamic> json) =>
      FaceEnrollmentList(
        items: (json['items'] as List? ?? [])
            .map((e) => FaceEnrollmentItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        enrolled: (json['enrolled'] as num?)?.toInt() ?? 0,
      );
}
