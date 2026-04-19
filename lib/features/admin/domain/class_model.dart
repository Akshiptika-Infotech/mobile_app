class Section {
  const Section({required this.id, required this.name, required this.classId});

  final String id;
  final String name;
  final String classId;

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        classId: (json['classId'] ?? '').toString(),
      );
}

class SchoolClass {
  final String id;
  final String name;
  final String academicYear;
  final List<String> sections;

  const SchoolClass({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.sections,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        academicYear: json['academicYear']?.toString() ?? '',
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class AcademicYear {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final bool isActive;

  const AcademicYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory AcademicYear.fromJson(Map<String, dynamic> json) => AcademicYear(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        isActive: json['isActive'] == true,
      );
}
