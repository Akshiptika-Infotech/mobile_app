/// Fee matrix returned by
/// `GET /api/parent/children/:studentId/matrix?academicYearId=...`.
class FeeMatrix {
  const FeeMatrix({
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    this.className,
    this.section,
    this.photoPath,
    required this.academicYearId,
    required this.academicYearName,
    required this.rows,
  });

  final String studentId;
  final String studentName;
  final String admissionNumber;
  final String? className;
  final String? section;
  final String? photoPath;
  final String academicYearId;
  final String academicYearName;
  final List<FeeRow> rows;

  /// Total amount currently due across every unpaid cell.
  double get totalDue {
    var sum = 0.0;
    for (final r in rows) {
      for (final c in r.cells) {
        if (!c.isPaid) sum += c.amountDue;
      }
    }
    return sum;
  }

  /// Total amount that has been collected so far.
  double get totalPaid {
    var sum = 0.0;
    for (final r in rows) {
      for (final c in r.cells) {
        if (c.isPaid) sum += c.amountDue;
      }
    }
    return sum;
  }

  factory FeeMatrix.fromJson(Map<String, dynamic> json) {
    final student =
        (json['student'] as Map?)?.cast<String, dynamic>() ?? const {};
    final year =
        (json['academicYear'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rowList = (json['rows'] as List? ?? const []);
    return FeeMatrix(
      studentId: (student['id'] ?? '').toString(),
      studentName: (student['name'] ?? '').toString(),
      admissionNumber: (student['admissionNumber'] ?? '').toString(),
      className: student['class']?.toString(),
      section: student['section']?.toString(),
      photoPath: student['photoPath']?.toString(),
      academicYearId: (year['id'] ?? '').toString(),
      academicYearName: (year['name'] ?? '').toString(),
      rows: rowList
          .map((r) => FeeRow.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeeRow {
  const FeeRow({
    required this.feeTypeId,
    required this.feeTypeName,
    required this.feeTypeCategory,
    this.stoppageName,
    required this.cells,
  });

  final String feeTypeId;
  final String feeTypeName;

  /// `ONE_TIME` | `MONTHLY` | `ANNUAL` | `TRANSPORT`.
  final String feeTypeCategory;
  final String? stoppageName;
  final List<FeeCell> cells;

  bool get isOneTime =>
      feeTypeCategory == 'ONE_TIME' || feeTypeCategory == 'ANNUAL';

  factory FeeRow.fromJson(Map<String, dynamic> json) {
    final cellsRaw = (json['cells'] as List? ?? const []);
    return FeeRow(
      feeTypeId: (json['feeTypeId'] ?? '').toString(),
      feeTypeName: (json['feeTypeName'] ?? '').toString(),
      feeTypeCategory: (json['feeTypeCategory'] ?? '').toString(),
      stoppageName: json['stoppageName']?.toString(),
      cells: cellsRaw
          .map((c) => FeeCell.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeeCell {
  const FeeCell({
    required this.monthYear,
    required this.baseAmount,
    required this.concessionAmount,
    required this.netAmount,
    required this.lateFeeAmount,
    required this.amountDue,
    this.stoppageName,
    required this.isPaid,
    this.collectionId,
    this.receiptNumber,
  });

  /// Either `ONE_TIME` (for one-time fees) or `MMM-YYYY` e.g. `Apr-2026`.
  final String monthYear;
  final double baseAmount;
  final double concessionAmount;
  final double netAmount;
  final double lateFeeAmount;
  final double amountDue;
  final String? stoppageName;
  final bool isPaid;
  final String? collectionId;
  final String? receiptNumber;

  bool get isOneTime => monthYear == 'ONE_TIME';

  factory FeeCell.fromJson(Map<String, dynamic> json) {
    final line = (json['line'] as Map?)?.cast<String, dynamic>() ?? const {};
    return FeeCell(
      monthYear: (json['monthYear'] ?? '').toString(),
      baseAmount: _d(line['baseAmount']),
      concessionAmount: _d(line['concessionAmount']),
      netAmount: _d(line['netAmount']),
      lateFeeAmount: _d(line['lateFeeAmount']),
      amountDue: _d(line['amountDue']),
      stoppageName: line['stoppageName']?.toString(),
      isPaid: json['isPaid'] == true,
      collectionId: json['collectionId']?.toString(),
      receiptNumber: json['receiptNumber']?.toString(),
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

/// Selection passed into the Razorpay create-order call.
class SelectedFeeLine {
  const SelectedFeeLine({
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
