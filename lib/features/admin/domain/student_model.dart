class StudentModel {
  const StudentModel({
    required this.id,
    required this.name,
    required this.className,
    required this.section,
    required this.rollNumber,
    required this.admissionNumber,
    required this.status,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.religion,
    this.category,
    this.house,
    this.address,
    this.academicYear,
    this.academicYearId,
    this.transportRoute,
    this.transportRouteId,
    this.photoUrl,
    this.fatherName,
    this.fatherPhone,
    this.motherName,
    this.motherPhone,
    this.parentEmail,
    this.fatherOccupation,
    this.motherOccupation,
  });

  final String id;
  final String name;
  final String className;
  final String section;
  final String rollNumber;
  final String admissionNumber;
  final String status;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? religion;
  final String? category;
  final String? house;
  final String? address;
  final String? academicYear;
  final String? academicYearId;
  final String? transportRoute;
  final String? transportRouteId;
  final String? photoUrl;
  final String? fatherName;
  final String? fatherPhone;
  final String? motherName;
  final String? motherPhone;
  final String? parentEmail;
  final String? fatherOccupation;
  final String? motherOccupation;

  static String _buildName(Map<String, dynamic> json) {
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      return json['name'].toString();
    }
    final parts = [
      json['firstName'],
      json['middleName'],
      json['lastName'],
    ].where((p) => p != null && p.toString().isNotEmpty).map((p) => p.toString());
    final full = parts.join(' ').trim();
    return full.isNotEmpty ? full : '';
  }

  static String _extractNested(dynamic value) {
    if (value is Map<String, dynamic>) return (value['name'] ?? '').toString();
    if (value != null) return value.toString();
    return '';
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: (json['id'] ?? '').toString(),
      name: _buildName(json),
      className: _extractNested(json['class']).isNotEmpty
          ? _extractNested(json['class'])
          : (json['className'] ?? '').toString(),
      section: _extractNested(json['section']),
      rollNumber: (json['rollNumber'] ?? json['roll_number'] ?? '').toString(),
      admissionNumber:
          (json['admissionNumber'] ?? json['admission_number'] ?? '')
              .toString(),
      status: (json['status'] ?? 'active').toString(),
      dob: (json['dob'] ?? json['dateOfBirth'])?.toString(),
      gender: _extractNested(json['gender']).isNotEmpty
          ? _extractNested(json['gender'])
          : null,
      bloodGroup: _extractNested(json['bloodGroup'] ?? json['blood_group'])
          .isNotEmpty
          ? _extractNested(json['bloodGroup'] ?? json['blood_group'])
          : null,
      religion: _extractNested(json['religion']).isNotEmpty
          ? _extractNested(json['religion'])
          : null,
      category: _extractNested(json['category']).isNotEmpty
          ? _extractNested(json['category'])
          : null,
      house: _extractNested(json['house']).isNotEmpty
          ? _extractNested(json['house'])
          : null,
      // Address isn't on the Student model itself — it's stored on the
      // related StudentParent row (fatherAddress / motherAddress). Fall back
      // to top-level keys for list endpoints that flatten the shape.
      address: _parentField(json, 'fatherAddress', 'father_address') ??
          _parentField(json, 'motherAddress', 'mother_address') ??
          (json['address'] ?? json['currentAddress'])?.toString(),
      academicYear: _extractNested(json['academicYear'] ?? json['academic_year'])
          .isNotEmpty
          ? _extractNested(json['academicYear'] ?? json['academic_year'])
          : null,
      academicYearId: (json['academicYearId'] ?? json['academic_year_id'])
          ?.toString(),
      transportRoute:
          _extractNested(json['transportRoute'] ?? json['transport_route'])
              .isNotEmpty
              ? _extractNested(
                  json['transportRoute'] ?? json['transport_route'])
              : null,
      // The detail endpoint returns transportAssignment.routeId — keep the id
      // around so the detail screen can resolve the route name from the
      // transport-routes lookup.
      transportRouteId: () {
        final ta = json['transportAssignment'];
        if (ta is Map<String, dynamic>) {
          final id = ta['routeId'] ?? ta['route_id'];
          if (id != null && id.toString().isNotEmpty) return id.toString();
        }
        final top = json['transportRouteId'] ?? json['transport_route_id'];
        return top?.toString();
      }(),
      photoUrl: (json['photoUrl'] ?? json['photo_url'] ?? json['photoPath'] ?? json['photo_path'] ?? json['photo'])?.toString(),
      // Parent fields are nested under `parent` on the detail endpoint
      // (Prisma returns the full StudentParent row); fall back to the
      // top-level keys for any list endpoint that flattens them.
      fatherName: _parentField(json, 'fatherName', 'father_name'),
      fatherPhone: _parentField(json, 'fatherContact', 'father_contact', alt: 'fatherPhone'),
      motherName: _parentField(json, 'motherName', 'mother_name'),
      motherPhone: _parentField(json, 'motherContact', 'mother_contact', alt: 'motherPhone'),
      parentEmail: _parentField(json, 'fatherEmail', 'father_email',
          alt: 'parentEmail') ??
          _parentField(json, 'motherEmail', 'mother_email'),
      fatherOccupation:
          _parentField(json, 'fatherOccupation', 'father_occupation'),
      motherOccupation:
          _parentField(json, 'motherOccupation', 'mother_occupation'),
    );
  }

  /// Looks for a parent-related field first inside `json['parent']` (the
  /// shape returned by `/api/admin/students/[id]` which includes the
  /// related StudentParent row) and then on the top-level JSON for
  /// flatter responses.
  static String? _parentField(
    Map<String, dynamic> json,
    String camel,
    String snake, {
    String? alt,
  }) {
    final parent = json['parent'];
    if (parent is Map<String, dynamic>) {
      final v = parent[camel] ?? parent[snake] ?? (alt != null ? parent[alt] : null);
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    final top = json[camel] ?? json[snake] ?? (alt != null ? json[alt] : null);
    return top?.toString();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'class': className,
        'section': section,
        'rollNumber': rollNumber,
        'admissionNumber': admissionNumber,
        'status': status,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (religion != null) 'religion': religion,
        if (category != null) 'category': category,
        if (house != null) 'house': house,
        if (address != null) 'address': address,
        if (academicYear != null) 'academicYear': academicYear,
        if (transportRoute != null) 'transportRoute': transportRoute,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (fatherName != null) 'fatherName': fatherName,
        if (fatherPhone != null) 'fatherPhone': fatherPhone,
        if (motherName != null) 'motherName': motherName,
        if (motherPhone != null) 'motherPhone': motherPhone,
        if (parentEmail != null) 'parentEmail': parentEmail,
        if (fatherOccupation != null) 'fatherOccupation': fatherOccupation,
        if (motherOccupation != null) 'motherOccupation': motherOccupation,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class StudentsPage {
  const StudentsPage({
    required this.students,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  final List<StudentModel> students;
  final int total;
  final int page;
  final bool hasMore;

  factory StudentsPage.fromJson(Map<String, dynamic> json) {
    final list = (json['students'] ?? json['data'] ?? <dynamic>[]) as List;
    final total = _toInt(json['total'] ?? list.length);
    final page = _toInt(json['page'] ?? 1);
    final perPage = _toInt(json['limit'] ?? json['perPage'] ?? json['per_page'] ?? 25);
    final hasMore = json['hasMore'] == true ||
        (json['hasMore'] == null && list.length >= perPage);
    return StudentsPage(
      students: list
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      page: page,
      hasMore: hasMore,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
