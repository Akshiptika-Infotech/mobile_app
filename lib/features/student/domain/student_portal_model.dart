// ── Shared ────────────────────────────────────────────────────────────────────

class AcademicYear {
  const AcademicYear({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  factory AcademicYear.fromJson(Map<String, dynamic> json) => AcademicYear(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        isActive: json['isActive'] == true,
      );
}

// ── Fee Matrix ────────────────────────────────────────────────────────────────

class FeeCell {
  const FeeCell({
    required this.monthYear,
    required this.gross,
    required this.concession,
    required this.net,
    required this.lateFee,
    required this.isPaid,
    this.collectionId,
    this.receiptNumber,
  });

  /// "2025-04" for monthly fees, "ONE_TIME" for one-time/annual fees.
  final String monthYear;
  final double gross;
  final double concession;
  final double net;
  final double lateFee;
  final bool isPaid;
  final String? collectionId;
  final String? receiptNumber;

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory FeeCell.fromJson(Map<String, dynamic> json) {
    // `line` is a FeeLineResult from the fee-calculator:
    // { baseAmount, concessionAmount, netAmount, lateFeeAmount, amountDue }
    final line = json['line'] as Map<String, dynamic>? ?? {};
    return FeeCell(
      monthYear: (json['monthYear'] ?? '').toString(),
      gross: _d(line['baseAmount']),
      concession: _d(line['concessionAmount']),
      net: _d(line['amountDue']),   // amountDue = netAmount + lateFeeAmount
      lateFee: _d(line['lateFeeAmount']),
      isPaid: json['isPaid'] == true,
      collectionId: json['collectionId']?.toString(),
      receiptNumber: json['receiptNumber']?.toString(),
    );
  }

  /// Human-readable label: "Apr 2025" or "One Time".
  String get label {
    if (monthYear == 'ONE_TIME') return 'One Time';
    final parts = monthYear.split('-');
    if (parts.length != 2) return monthYear;
    final month = int.tryParse(parts[1]) ?? 1;
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${names[month]} ${parts[0]}';
  }
}

class FeeRow {
  const FeeRow({
    required this.feeTypeId,
    required this.feeTypeName,
    required this.feeTypeCategory,
    required this.cells,
    this.stoppageName,
  });

  final String feeTypeId;
  final String feeTypeName;
  final String feeTypeCategory;
  final List<FeeCell> cells;
  final String? stoppageName; // only for TRANSPORT rows

  bool get isOneTime =>
      feeTypeCategory == 'ONE_TIME' || feeTypeCategory == 'ANNUAL';

  double get totalNet => cells.fold(0.0, (s, c) => s + c.net);
  double get totalPaid =>
      cells.where((c) => c.isPaid).fold(0.0, (s, c) => s + c.net);
  double get totalOutstanding => totalNet - totalPaid;
  int get paidCount => cells.where((c) => c.isPaid).length;

  factory FeeRow.fromJson(Map<String, dynamic> json) => FeeRow(
        feeTypeId: (json['feeTypeId'] ?? '').toString(),
        feeTypeName: (json['feeTypeName'] ?? '').toString(),
        feeTypeCategory: (json['feeTypeCategory'] ?? '').toString(),
        stoppageName: json['stoppageName']?.toString(),
        cells: (json['cells'] as List? ?? [])
            .map((e) => FeeCell.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FeeMatrixData {
  const FeeMatrixData({
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    required this.className,
    required this.section,
    required this.academicYearId,
    required this.academicYearName,
    required this.rows,
  });

  final String studentId;
  final String studentName;
  final String admissionNumber;
  final String className;
  final String section;
  final String academicYearId;
  final String academicYearName;
  final List<FeeRow> rows;

  double get totalNet => rows.fold(0.0, (s, r) => s + r.totalNet);
  double get totalPaid => rows.fold(0.0, (s, r) => s + r.totalPaid);
  double get totalOutstanding => totalNet - totalPaid;

  factory FeeMatrixData.fromJson(Map<String, dynamic> json) {
    final s = json['student'] as Map<String, dynamic>? ?? {};
    final ay = json['academicYear'] as Map<String, dynamic>? ?? {};
    return FeeMatrixData(
      studentId: (s['id'] ?? '').toString(),
      studentName: (s['name'] ?? '').toString(),
      admissionNumber: (s['admissionNumber'] ?? '').toString(),
      className: (s['class'] ?? '').toString(),
      section: (s['section'] ?? '').toString(),
      academicYearId: (ay['id'] ?? '').toString(),
      academicYearName: (ay['name'] ?? '').toString(),
      rows: (json['rows'] as List? ?? [])
          .map((e) => FeeRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Payment ───────────────────────────────────────────────────────────────────

class SelectedPaymentItem {
  const SelectedPaymentItem({
    required this.feeTypeId,
    required this.feeTypeName,
    required this.monthYear,
    this.stoppageName,
    required this.amountCharged,
    required this.concessionAmount,
    required this.lateFeeAmount,
    required this.amountPaid,
  });

  final String feeTypeId;
  final String feeTypeName;
  final String monthYear;
  final String? stoppageName;
  final double amountCharged;
  final double concessionAmount;
  final double lateFeeAmount;
  final double amountPaid;

  Map<String, dynamic> toJson() => {
        'feeTypeId': feeTypeId,
        'feeTypeName': feeTypeName,
        'monthYear': monthYear,
        if (stoppageName != null) 'stoppageName': stoppageName,
        'amountCharged': amountCharged,
        'concessionAmount': concessionAmount,
        'lateFeeAmount': lateFeeAmount,
        'amountPaid': amountPaid,
      };
}

class CreateOrderResponse {
  const CreateOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentId,
    required this.key,
  });

  final String orderId;
  final int amount; // in paise
  final String currency;
  final String paymentId; // our DB record id
  final String key; // Razorpay key id

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      CreateOrderResponse(
        orderId: (json['orderId'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        currency: (json['currency'] ?? 'INR').toString(),
        paymentId: (json['paymentId'] ?? '').toString(),
        key: (json['key'] ?? '').toString(),
      );
}

// ── Receipts ──────────────────────────────────────────────────────────────────

class ReceiptItem {
  const ReceiptItem({required this.name, required this.amount});

  final String name;
  final double amount;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        name: (json['feeType'] as Map<String, dynamic>?)?['name']?.toString() ??
            '',
        amount: json['amount'] is num
            ? (json['amount'] as num).toDouble()
            : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      );
}

class StudentReceipt {
  const StudentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.collectedAt,
    required this.paymentMode,
    required this.status,
    required this.items,
    required this.academicYearName,
    this.isRevoked = false,
  });

  final String id;
  final String receiptNumber;
  final String collectedAt;
  final String paymentMode;
  final String status;
  final List<ReceiptItem> items;
  final String academicYearName;
  final bool isRevoked;

  double get total => items.fold(0.0, (s, i) => s + i.amount);

  factory StudentReceipt.fromJson(Map<String, dynamic> json) => StudentReceipt(
        id: (json['id'] ?? '').toString(),
        receiptNumber: (json['receiptNumber'] ?? '').toString(),
        collectedAt: (json['collectedAt'] ?? json['date'] ?? '').toString(),
        paymentMode: (json['paymentMode'] ?? '').toString(),
        status: (json['status'] ?? 'COLLECTED').toString(),
        items: (json['items'] as List? ?? [])
            .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        academicYearName:
            (json['academicYear'] as Map<String, dynamic>?)?['name']
                    ?.toString() ??
                '',
        isRevoked: json['revocation'] != null,
      );
}

// ── Transport ─────────────────────────────────────────────────────────────────

class RouteStoppage {
  const RouteStoppage({required this.name, required this.order});

  final String name;
  final int order;

  factory RouteStoppage.fromJson(Map<String, dynamic> json) => RouteStoppage(
        name: (json['name'] ?? '').toString(),
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}

class StudentTransportInfo {
  const StudentTransportInfo({
    required this.routeName,
    required this.myStoppage,
    required this.stoppages,
  });

  final String routeName;
  final String myStoppage;
  final List<RouteStoppage> stoppages;

  factory StudentTransportInfo.fromJson(Map<String, dynamic> json) {
    final assignment = json['assignment'] as Map<String, dynamic>?;
    if (assignment == null) {
      return const StudentTransportInfo(
          routeName: '', myStoppage: '', stoppages: []);
    }
    final route = assignment['route'] as Map<String, dynamic>? ?? {};
    final stoppage = assignment['stoppage'] as Map<String, dynamic>? ?? {};
    return StudentTransportInfo(
      routeName: (route['name'] ?? '').toString(),
      myStoppage: (stoppage['name'] ?? '').toString(),
      stoppages: (route['stoppages'] as List? ?? [])
          .map((e) => RouteStoppage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
