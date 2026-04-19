class ReportRow {
  final Map<String, dynamic> data;
  const ReportRow(this.data);
  factory ReportRow.fromJson(Map<String, dynamic> json) => ReportRow(json);
}
