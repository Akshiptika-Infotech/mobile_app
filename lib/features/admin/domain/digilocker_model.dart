class DigiLockerPin {
  final String studentId;
  final String studentName;
  final String admissionNumber;
  final String pin;

  const DigiLockerPin({
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    required this.pin,
  });

  factory DigiLockerPin.fromJson(Map<String, dynamic> json) => DigiLockerPin(
        studentId: json['studentId']?.toString() ?? '',
        studentName: json['studentName']?.toString() ?? '',
        admissionNumber: json['admissionNumber']?.toString() ?? '',
        pin: json['pin']?.toString() ?? '',
      );
}
