class SentNotification {
  final String id;
  final String title;
  final String message;
  final String targetRole;
  final String sentAt;
  final String? targetClass;
  final int deliveredCount;

  const SentNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.targetRole,
    required this.sentAt,
    this.targetClass,
    required this.deliveredCount,
  });

  factory SentNotification.fromJson(Map<String, dynamic> json) =>
      SentNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        targetRole: json['targetRole']?.toString() ?? '',
        sentAt: json['sentAt']?.toString() ?? '',
        targetClass: json['targetClass']?.toString(),
        deliveredCount: (json['deliveredCount'] as num?)?.toInt() ?? 0,
      );
}
