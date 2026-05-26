/// Paginated receipt envelope returned by `GET /api/parent/receipts`.
class ParentReceiptsPage {
  const ParentReceiptsPage({
    required this.collections,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<ParentReceipt> collections;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory ParentReceiptsPage.fromJson(Map<String, dynamic> json) {
    final list = (json['collections'] as List? ?? const []);
    return ParentReceiptsPage(
      collections: list
          .map((e) => ParentReceipt.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: _i(json['total']),
      page: _i(json['page'] ?? 1),
      limit: _i(json['limit'] ?? 20),
    );
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class ParentReceipt {
  const ParentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.collectedAt,
    required this.totalAmount,
    this.paymentMethod,
    required this.studentName,
    this.admissionNumber,
    this.className,
    this.academicYearName,
    required this.items,
    required this.isRevoked,
  });

  final String id;
  final String receiptNumber;
  final DateTime collectedAt;
  final double totalAmount;
  final String? paymentMethod;
  final String studentName;
  final String? admissionNumber;
  final String? className;
  final String? academicYearName;
  final List<ParentReceiptItem> items;
  final bool isRevoked;

  factory ParentReceipt.fromJson(Map<String, dynamic> json) {
    final student =
        (json['student'] as Map?)?.cast<String, dynamic>() ?? const {};
    final year =
        (json['academicYear'] as Map?)?.cast<String, dynamic>() ?? const {};
    final cls = student['class'];
    final first = (student['firstName'] ?? '').toString();
    final last = (student['lastName'] ?? '').toString();
    final name = '$first $last'.trim();
    final items = (json['items'] as List? ?? const [])
        .map((i) => ParentReceiptItem.fromJson(i as Map<String, dynamic>))
        .toList();
    return ParentReceipt(
      id: (json['id'] ?? '').toString(),
      receiptNumber:
          (json['receiptNumber'] ?? json['id'] ?? '').toString(),
      collectedAt:
          DateTime.tryParse(json['collectedAt']?.toString() ?? '') ??
              DateTime.now(),
      totalAmount: _d(json['totalAmount'] ?? json['amount']),
      paymentMethod: json['paymentMethod']?.toString(),
      studentName: name,
      admissionNumber: student['admissionNumber']?.toString(),
      className: cls is Map ? cls['name']?.toString() : null,
      academicYearName: year['name']?.toString(),
      items: items,
      isRevoked: json['revocation'] != null,
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class ParentReceiptItem {
  const ParentReceiptItem({
    required this.feeTypeName,
    required this.monthYear,
    required this.amountPaid,
  });

  final String feeTypeName;
  final String monthYear;
  final double amountPaid;

  factory ParentReceiptItem.fromJson(Map<String, dynamic> json) {
    final ft = (json['feeType'] as Map?)?.cast<String, dynamic>();
    return ParentReceiptItem(
      feeTypeName: (ft?['name'] ?? json['feeTypeName'] ?? '').toString(),
      monthYear: (json['monthYear'] ?? '').toString(),
      amountPaid: ParentReceipt._d(json['amountPaid'] ?? json['amount']),
    );
  }
}
