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
  late String _currentType;

  // (slug used in /api/admin/reports/{slug}, label shown in chips/title).
  // Order here drives the order of the chip strip.
  static const _types = <(String, String)>[
    ('collection',       'Collection'),
    ('defaulters',       'Defaulters'),
    ('receipts',         'Receipts'),
    ('students',         'Student Strength'),
    ('transport',        'Transport Fees'),
    ('concessions',      'Concessions'),
    ('staff-attendance', 'Staff Attendance'),
  ];

  String _label(String slug) =>
      _types.firstWhere((t) => t.$1 == slug, orElse: () => (slug, 'Report')).$2;

  String get _title => '${_label(_currentType)} Report';

  ReportParams get _params => ReportParams(
        type: _currentType,
        from: _range != null ? _dateFmt.format(_range!.start) : null,
        to: _range != null ? _dateFmt.format(_range!.end) : null,
      );

  @override
  void initState() {
    super.initState();
    _currentType = widget.reportType;
  }

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
      body: Column(
        children: [
          // ── Report type chips ───────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (slug, label) = _types[i];
                final selected = slug == _currentType;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) {
                    if (slug == _currentType) return;
                    setState(() => _currentType = slug);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: reportAsync.when(
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
          ),
        ],
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

  // ── Display helpers ────────────────────────────────────────────────────────

  /// Hide opaque IDs, denormalised foreign-key fields and stringified array
  /// columns. Drives both column header and row-cell rendering so `_sort()`
  /// also operates on the same visible set.
  static const _hidden = {
    'id', 'studentId', 'userId', 'collectedById', 'staffId',
    'classId', 'sectionId', 'academicYearId', 'feeTypeId',
    'concessionTypeId', 'routeId', 'stoppageId',
    'items', // raw stringified arrays — exported in CSV but cluttered on screen
  };

  /// Friendly column titles. Falls back to raw key for anything not listed.
  static const _titles = <String, String>{
    'receiptNumber': 'Receipt #',
    'studentName':   'Student',
    'admissionNumber': 'Adm #',
    'className':     'Class',
    'sectionName':   'Section',
    'monthYear':     'Month',
    'totalAmount':   'Amount',
    'amountPaid':    'Paid',
    'amountDue':     'Due',
    'totalPaid':     'Paid',
    'totalDue':      'Due',
    'paymentMode':   'Mode',
    'collectedBy':   'Collected By',
    'collectedAt':   'Date',
    'createdAt':     'Created',
    'staffName':     'Staff',
    'feeTypeName':   'Fee Type',
    'concessionType': 'Concession',
    'fromDate':      'From',
    'toDate':        'To',
    'leaveType':     'Leave Type',
    'reason':        'Reason',
  };

  static const _moneyKeys = {
    'totalAmount', 'amountPaid', 'amountDue',
    'totalPaid',   'totalDue',   'concessionAmount',
    'lateFeeAmount', 'balance', 'fee', 'feeAmount',
  };

  static final _money = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  String _formatCell(String key, dynamic raw) {
    if (raw == null) return '—';
    if (raw is List) return raw.length.toString();
    if (raw is Map) return '—';
    final s = raw.toString();
    if (s.isEmpty) return '—';

    // Money columns
    if (_moneyKeys.contains(key)) {
      final n = num.tryParse(s);
      if (n != null) return _money.format(n);
    }

    // ISO datetimes → "06 Apr 2026"
    if (s.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(s));
      } catch (_) {/* fall through */}
    }

    return s;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Build the visible column set from every row's keys (some rows may
    // include optional fields), then filter and order.
    final keySet = <String>{};
    for (final r in widget.rows) {
      keySet.addAll(r.keys);
    }
    final columns = keySet.where((k) => !_hidden.contains(k)).toList();

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
            final col = e.value;
            return DataColumn(
              label: Text(_titles[col] ?? col,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onSort: (col, _) => _sort(col, columns),
            );
          }).toList(),
          rows: _sorted.map((row) {
            return DataRow(
              cells: columns
                  .map((c) => DataCell(Text(_formatCell(c, row[c]))))
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
