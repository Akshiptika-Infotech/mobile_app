class CertificateModel {
  const CertificateModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.issueDate,
    this.url,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String type;
  final String issueDate;
  final String? url;

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: (json['studentName'] ?? json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      issueDate: (json['issueDate'] ?? json['date'] ?? '').toString(),
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'type': type,
        'issueDate': issueDate,
        if (url != null) 'url': url,
      };

  CertificateModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? type,
    String? issueDate,
    String? url,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      type: type ?? this.type,
      issueDate: issueDate ?? this.issueDate,
      url: url ?? this.url,
    );
  }
}
