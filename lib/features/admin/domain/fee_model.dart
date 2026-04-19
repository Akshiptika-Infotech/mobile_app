class FeeMonth {
  const FeeMonth({
    required this.month,
    required this.year,
    required this.feeType,
    required this.amount,
    required this.status,
    this.receiptNumber,
    this.paidDate,
  });

  final String month;
  final int year;
  final String feeType;
  final double amount;
  final String status; // 'paid' | 'due' | 'na'
  final String? receiptNumber;
  final String? paidDate;

  bool get isPaid => status == 'paid';
  bool get isDue => status == 'due';

  factory FeeMonth.fromJson(Map<String, dynamic> json) {
    return FeeMonth(
      month: (json['month'] ?? '').toString(),
      year: _toInt(json['year'] ?? 0),
      feeType: (json['feeType'] ?? json['fee_type'] ?? '').toString(),
      amount: _toDouble(json['amount'] ?? 0),
      status: (json['status'] ?? 'due').toString(),
      receiptNumber:
          (json['receiptNumber'] ?? json['receipt_number'])?.toString(),
      paidDate: (json['paidDate'] ?? json['paid_date'])?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class FeeStudentSummary {
  const FeeStudentSummary({
    required this.id,
    required this.name,
    required this.admissionNumber,
    required this.className,
    required this.section,
    required this.feeMatrix,
  });

  final String id;
  final String name;
  final String admissionNumber;
  final String className;
  final String section;
  final List<FeeMonth> feeMatrix;

  factory FeeStudentSummary.fromJson(Map<String, dynamic> json) {
    final matrixList =
        (json['feeMatrix'] ?? json['fee_matrix'] ?? <dynamic>[]) as List;

    // Build name from firstName, middleName, lastName if available
    String name;
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      name = json['name'].toString();
    } else {
      final parts = [
        json['firstName'],
        json['middleName'],
        json['lastName'],
      ].where((p) => p != null && p.toString().isNotEmpty).map((p) => p.toString());
      name = parts.join(' ').trim();
    }

    // Extract class/section from nested objects or use direct values
    String className = (json['class'] ?? json['className'] ?? '').toString();
    if (json['class'] is Map<String, dynamic>) {
      className = (json['class']['name'] ?? '').toString();
    }

    String section = (json['section'] ?? '').toString();
    if (json['section'] is Map<String, dynamic>) {
      section = (json['section']['name'] ?? '').toString();
    }

    return FeeStudentSummary(
      id: (json['id'] ?? '').toString(),
      name: name,
      admissionNumber:
          (json['admissionNumber'] ?? json['admission_number'] ?? '')
              .toString(),
      className: className,
      section: section,
      feeMatrix: matrixList
          .map((e) => FeeMonth.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FeeSearchResult {
  const FeeSearchResult({
    required this.id,
    required this.name,
    required this.admissionNumber,
    required this.className,
    required this.section,
  });

  final String id;
  final String name;
  final String admissionNumber;
  final String className;
  final String section;

  factory FeeSearchResult.fromJson(Map<String, dynamic> json) {
    // Build name from firstName, middleName, lastName if available
    String name;
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      name = json['name'].toString();
    } else {
      final parts = [
        json['firstName'],
        json['middleName'],
        json['lastName'],
      ].where((p) => p != null && p.toString().isNotEmpty).map((p) => p.toString());
      name = parts.join(' ').trim();
    }

    // Extract class/section from nested objects or use direct values
    String className = (json['class'] ?? json['className'] ?? '').toString();
    if (json['class'] is Map<String, dynamic>) {
      className = (json['class']['name'] ?? '').toString();
    }

    String section = (json['section'] ?? '').toString();
    if (json['section'] is Map<String, dynamic>) {
      section = (json['section']['name'] ?? '').toString();
    }

    return FeeSearchResult(
      id: (json['id'] ?? '').toString(),
      name: name,
      admissionNumber:
          (json['admissionNumber'] ?? json['admission_number'] ?? '')
              .toString(),
      className: className,
      section: section,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class FeeReceipt {
  const FeeReceipt({
    required this.receiptNumber,
    required this.studentName,
    required this.admissionNumber,
    required this.className,
    required this.section,
    required this.amount,
    required this.paymentMode,
    required this.date,
    required this.months,
  });

  final String receiptNumber;
  final String studentName;
  final String admissionNumber;
  final String className;
  final String section;
  final double amount;
  final String paymentMode;
  final String date;
  final List<String> months;

  factory FeeReceipt.fromJson(Map<String, dynamic> json) {
    final monthsList =
        (json['months'] ?? <dynamic>[]) as List<dynamic>;
    return FeeReceipt(
      receiptNumber:
          (json['receiptNumber'] ?? json['receipt_number'] ?? '').toString(),
      studentName: (json['studentName'] ?? json['student_name'] ?? '')
          .toString(),
      admissionNumber:
          (json['admissionNumber'] ?? json['admission_number'] ?? '')
              .toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      amount: _toDouble(json['amount'] ?? 0),
      paymentMode:
          (json['paymentMode'] ?? json['payment_mode'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      months: monthsList.map((e) => e.toString()).toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class FeeHistoryItem {
  const FeeHistoryItem({
    required this.id,
    required this.studentName,
    required this.admissionNumber,
    required this.amount,
    required this.date,
    required this.paymentMode,
    required this.receiptNumber,
    this.className,
  });

  final String id;
  final String studentName;
  final String admissionNumber;
  final double amount;
  final String date;
  final String paymentMode;
  final String receiptNumber;
  final String? className;

  factory FeeHistoryItem.fromJson(Map<String, dynamic> json) {
    return FeeHistoryItem(
      id: (json['id'] ?? '').toString(),
      studentName:
          (json['studentName'] ?? json['student_name'] ?? '').toString(),
      admissionNumber:
          (json['admissionNumber'] ?? json['admission_number'] ?? '')
              .toString(),
      amount: _toDouble(json['amount'] ?? 0),
      date: (json['date'] ?? '').toString(),
      paymentMode:
          (json['paymentMode'] ?? json['payment_mode'] ?? '').toString(),
      receiptNumber:
          (json['receiptNumber'] ?? json['receipt_number'] ?? '').toString(),
      className: (json['class'] ?? json['className'])?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
