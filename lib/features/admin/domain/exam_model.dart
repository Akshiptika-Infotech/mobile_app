class ExamSubject {
  const ExamSubject({
    required this.id,
    required this.subjectId,
    required this.examTypeId,
    required this.classId,
    this.sectionId,
    required this.name,
    required this.examType,
    required this.className,
    required this.section,
    required this.maxMarks,
    required this.passingMarks,
    this.isGraded = false,
    this.locked = false,
    this.marksEntryDeadline,
  });

  final String id;
  final String subjectId;
  final String examTypeId;
  final String classId;
  final String? sectionId;
  final String name;
  final String examType;
  final String className;
  final String section;
  final int maxMarks;
  final int passingMarks;
  final bool isGraded;

  /// `true` means marks entry is closed for this subject×exam-type — the
  /// Mark Entry screen must render read-only for teachers.
  final bool locked;

  /// Last day teachers may edit marks. `null` means no deadline (open).
  final DateTime? marksEntryDeadline;

  /// Whole days from today until the deadline. Negative if past, `null` if
  /// there is no deadline. Compared at day granularity (time-of-day ignored).
  int? get daysUntilDeadline {
    final d = marksEntryDeadline;
    if (d == null) return null;
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  factory ExamSubject.fromJson(Map<String, dynamic> json) {
    return ExamSubject(
      id: (json['id'] ?? '').toString(),
      subjectId: (json['subjectId'] ?? json['subject_id'] ?? '').toString(),
      examTypeId: (json['examTypeId'] ?? json['exam_type_id'] ?? '').toString(),
      classId: (json['classId'] ?? json['class_id'] ?? '').toString(),
      sectionId: (json['sectionId'] ?? json['section_id'])?.toString(),
      name: (json['name'] ?? json['subject'] ?? '').toString(),
      examType:
          (json['examType'] ?? json['exam_type'] ?? '').toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      maxMarks: _toInt(json['maxMarks'] ?? json['max_marks'] ?? 100),
      passingMarks:
          _toInt(json['passingMarks'] ?? json['passing_marks'] ?? 35),
      isGraded: json['isGraded'] == true,
      locked: json['locked'] == true,
      marksEntryDeadline:
          _toDate(json['marksEntryDeadline'] ?? json['marks_entry_deadline']),
    );
  }

  ExamSubject copyWith({
    bool? locked,
    DateTime? marksEntryDeadline,
  }) {
    return ExamSubject(
      id: id,
      subjectId: subjectId,
      examTypeId: examTypeId,
      classId: classId,
      sectionId: sectionId,
      name: name,
      examType: examType,
      className: className,
      section: section,
      maxMarks: maxMarks,
      passingMarks: passingMarks,
      isGraded: isGraded,
      locked: locked ?? this.locked,
      marksEntryDeadline: marksEntryDeadline ?? this.marksEntryDeadline,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }
}

class StudentMark {
  StudentMark({
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    this.photoUrl,
    this.marksObtained,
    this.grade,
    this.remarks,
  });

  final String studentId;
  final String studentName;
  final String admissionNumber;
  final String? photoUrl;
  int? marksObtained;
  String? grade;
  String? remarks;

  factory StudentMark.fromJson(Map<String, dynamic> json) {
    return StudentMark(
      studentId:
          (json['studentId'] ?? json['student_id'] ?? '').toString(),
      studentName:
          (json['studentName'] ?? json['student_name'] ?? '').toString(),
      admissionNumber:
          (json['admissionNumber'] ?? json['admission_number'] ?? '')
              .toString(),
      photoUrl: (json['photoUrl'] ??
              json['photo_url'] ??
              json['photoPath'] ??
              json['photo_path'])
          ?.toString(),
      marksObtained: json['marksObtained'] != null
          ? _toInt(json['marksObtained'])
          : json['marks_obtained'] != null
              ? _toInt(json['marks_obtained'])
              : null,
      grade: json['grade']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        if (marksObtained != null) 'marksObtained': marksObtained,
        if (grade != null) 'grade': grade,
        if (remarks != null) 'remarks': remarks,
      };

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class ReportCard {
  const ReportCard({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
    required this.subjects,
    required this.percentage,
    required this.grade,
  });

  final String studentId;
  final String studentName;
  final String className;
  final String section;
  final List<SubjectResult> subjects;
  final double percentage;
  final String grade;

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    final subjectList =
        (json['subjects'] ?? <dynamic>[]) as List;
    return ReportCard(
      studentId:
          (json['studentId'] ?? json['student_id'] ?? '').toString(),
      studentName:
          (json['studentName'] ?? json['student_name'] ?? '').toString(),
      className: (json['class'] ?? json['className'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      subjects: subjectList
          .map((e) =>
              SubjectResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      percentage: _toDouble(json['percentage'] ?? 0),
      grade: (json['grade'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class TeacherExamSubject {
  const TeacherExamSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.isGraded,
    this.classId,
    this.sectionId,
  });

  final String id;
  final String name;
  final String code;
  final bool isGraded;
  final String? classId;
  final String? sectionId;

  factory TeacherExamSubject.fromJson(Map<String, dynamic> json) {
    return TeacherExamSubject(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      isGraded: json['isGraded'] == true,
      classId: json['classId']?.toString(),
      sectionId: json['sectionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'isGraded': isGraded,
      };

  TeacherExamSubject copyWith({
    String? id,
    String? name,
    String? code,
    bool? isGraded,
    String? classId,
    String? sectionId,
  }) {
    return TeacherExamSubject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isGraded: isGraded ?? this.isGraded,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
    );
  }
}

class SubjectResult {
  const SubjectResult({
    required this.subject,
    required this.examType,
    required this.maxMarks,
    required this.marksObtained,
    required this.passingMarks,
    required this.grade,
  });

  final String subject;
  final String examType;
  final int maxMarks;
  final int marksObtained;
  final int passingMarks;
  final String grade;

  bool get isPassing => marksObtained >= passingMarks;

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      subject: (json['subject'] ?? json['name'] ?? '').toString(),
      examType:
          (json['examType'] ?? json['exam_type'] ?? '').toString(),
      maxMarks: _toInt(json['maxMarks'] ?? json['max_marks'] ?? 100),
      marksObtained:
          _toInt(json['marksObtained'] ?? json['marks_obtained'] ?? 0),
      passingMarks:
          _toInt(json['passingMarks'] ?? json['passing_marks'] ?? 35),
      grade: (json['grade'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
