class FeeType {
  final String id;
  final String name;
  final String description;
  final bool isOptional;

  const FeeType({
    required this.id,
    required this.name,
    required this.description,
    required this.isOptional,
  });

  factory FeeType.fromJson(Map<String, dynamic> json) => FeeType(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        isOptional: json['isOptional'] == true,
      );
}

class FeeStructure {
  final String id;
  final String className;
  final String section;
  final String academicYear;
  final List<StructureItem> feeItems;

  const FeeStructure({
    required this.id,
    required this.className,
    required this.section,
    required this.academicYear,
    required this.feeItems,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) => FeeStructure(
        id: json['id']?.toString() ?? '',
        className: json['className']?.toString() ?? '',
        section: json['section']?.toString() ?? '',
        academicYear: json['academicYear']?.toString() ?? '',
        feeItems: (json['feeItems'] as List<dynamic>?)
                ?.map((e) => StructureItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class StructureItem {
  final String feeTypeId;
  final String feeTypeName;
  final double amount;
  final String dueDate;

  const StructureItem({
    required this.feeTypeId,
    required this.feeTypeName,
    required this.amount,
    required this.dueDate,
  });

  factory StructureItem.fromJson(Map<String, dynamic> json) => StructureItem(
        feeTypeId: json['feeTypeId']?.toString() ?? '',
        feeTypeName: json['feeTypeName']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        dueDate: json['dueDate']?.toString() ?? '',
      );
}

class ConcessionType {
  final String id;
  final String name;
  final String description;
  final String discountType;
  final double discountValue;

  const ConcessionType({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
  });

  factory ConcessionType.fromJson(Map<String, dynamic> json) => ConcessionType(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        discountType: json['discountType']?.toString() ?? '',
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      );
}

class LateFeeConfig {
  final int graceDays;
  final double finePerDay;
  final double maxFine;

  const LateFeeConfig({
    required this.graceDays,
    required this.finePerDay,
    required this.maxFine,
  });

  factory LateFeeConfig.fromJson(Map<String, dynamic> json) => LateFeeConfig(
        graceDays: (json['graceDays'] as num?)?.toInt() ?? 0,
        finePerDay: (json['finePerDay'] as num?)?.toDouble() ?? 0,
        maxFine: (json['maxFine'] as num?)?.toDouble() ?? 0,
      );
}
