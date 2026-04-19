class IdCardModel {
  const IdCardModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.generatedAt,
    this.url,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String generatedAt;
  final String? url;

  factory IdCardModel.fromJson(Map<String, dynamic> json) {
    return IdCardModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: (json['studentName'] ?? json['name'] ?? '').toString(),
      className: (json['className'] ?? json['class'] ?? '').toString(),
      generatedAt:
          (json['generatedAt'] ?? json['createdAt'] ?? '').toString(),
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'generatedAt': generatedAt,
        if (url != null) 'url': url,
      };

  IdCardModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? className,
    String? generatedAt,
    String? url,
  }) {
    return IdCardModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      generatedAt: generatedAt ?? this.generatedAt,
      url: url ?? this.url,
    );
  }
}
