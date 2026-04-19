class AppSettings {
  final String schoolName;
  final String contactEmail;
  final String contactPhone;
  final String logoUrl;
  final String activeAcademicYear;

  const AppSettings({
    required this.schoolName,
    required this.contactEmail,
    required this.contactPhone,
    required this.logoUrl,
    required this.activeAcademicYear,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        schoolName: json['schoolName']?.toString() ?? '',
        contactEmail: json['contactEmail']?.toString() ?? '',
        contactPhone: json['contactPhone']?.toString() ?? '',
        logoUrl: json['logoUrl']?.toString() ?? '',
        activeAcademicYear: json['activeAcademicYear']?.toString() ?? '',
      );
}
