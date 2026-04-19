import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/providers/report_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    super.key,
    required this.reportType,
  });

  final String reportType;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _displayFmt = DateFormat('dd MMM yyyy');
  DateTimeRange? _range;
  bool _isExporting = false;

  static const _titleMap = <String, String>{
    'collection': 'Collection Report',
    'defaulters': 'Defaulters Report',
    'receipts': 'Receipts Report',
    'students': 'Students Report',
    'staff-attendance': 'Staff Attendance Report',
    'transport': 'Transport Report',
    'concessions': 'Concessions Report',
  };

  String get _title => _titleMap[widget.reportType] ?? 'Report';

  ReportParams get _params => ReportParams(
        type: widget.reportType,
        from: _range != null ? _dateFmt.format(_range!.start) : null,
        to: _range != null ? _dateFmt.format(_range!.end) : null,
      );

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (!mounted || range == null) return;
    setState(() => _range = range);
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final columns = rows.first.keys.toList();
      final buffer = StringBuffer();
      buffer.writeln(columns.map(_csvEscape).join(','));
      for (final row in rows) {
        buffer.writeln(
          columns.map((c) => _csvEscape(row[c]?.toString() ?? '')).join(','),
        );
      }
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copied to clipboard')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reportAsync = ref.watch(reportProvider(_params));

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          reportAsync.whenOrNull(
            data: (rows) => IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_download_outlined),
              tooltip: 'Export CSV',
              onPressed: _isExporting || rows.isEmpty ? null : () => _exportCsv(rows),
            ),
          ) ?? const SizedBox.shrink(),
          if (_range != null)
            TextButton(
              onPressed: () => setState(() => _range = null),
              child: const Text('Clear'),
            ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Date range',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 10, itemHeight: 48),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(reportProvider(_params)),
        ),
        data: (rows) {
          return Column(
            children: [
              if (_range != null)
                Container(
                  color: cs.primaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: double.infinity,
                  child: Text(
                    '${_displayFmt.format(_range!.start)} – ${_displayFmt.format(_range!.end)}',
                    style: TextStyle(color: cs.onPrimaryContainer, fontSize: 13),
                  ),
                ),
              Expanded(
                child: rows.isEmpty
                    ? const AppEmptyState(
                        message: 'No data found for this report',
                        icon: Icons.assessment_outlined,
                      )
                    : _ReportTable(rows: rows),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Data Table ────────────────────────────────────────────────────────────────

class _ReportTable extends StatefulWidget {
  const _ReportTable({required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  State<_ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<_ReportTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late List<Map<String, dynamic>> _sorted;

  @override
  void initState() {
    super.initState();
    _sorted = List.from(widget.rows);
  }

  @override
  void didUpdateWidget(_ReportTable old) {
    super.didUpdateWidget(old);
    if (old.rows != widget.rows) {
      _sorted = List.from(widget.rows);
      _sortColumnIndex = null;
    }
  }

  void _sort(int colIndex, List<String> columns) {
    final col = columns[colIndex];
    setState(() {
      if (_sortColumnIndex == colIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = colIndex;
        _sortAscending = true;
      }
      _sorted.sort((a, b) {
        final av = a[col]?.toString() ?? '';
        final bv = b[col]?.toString() ?? '';
        final num? an = num.tryParse(av);
        final num? bn = num.tryParse(bv);
        final cmp = (an != null && bn != null) ? an.compareTo(bn) : av.compareTo(bv);
        return _sortAscending ? cmp : -cmp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final columns = widget.rows.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: columns.asMap().entries.map((e) {
            return DataColumn(
              label: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
              onSort: (col, _) => _sort(col, columns),
            );
          }).toList(),
          rows: _sorted.map((row) {
            return DataRow(
              cells: columns.map((c) => DataCell(Text(row[c]?.toString() ?? ''))).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
