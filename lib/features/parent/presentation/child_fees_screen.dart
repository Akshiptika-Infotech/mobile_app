import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:mobile_app/features/parent/data/parent_repository.dart';
import 'package:mobile_app/features/parent/providers/parent_provider.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';

// ── Internal data classes ─────────────────────────────────────────────────────

class _MonthEntry {
  const _MonthEntry({
    required this.feeTypeId,
    required this.feeTypeName,
    this.stoppageName,
    required this.cell,
  });
  final String feeTypeId;
  final String feeTypeName;
  final String? stoppageName;
  final FeeCell cell;
}

class _MonthGroup {
  const _MonthGroup({required this.monthYear, required this.entries});

  final String monthYear;
  final List<_MonthEntry> entries;

  bool get isFullyPaid => entries.every((e) => e.cell.isPaid);
  bool get isPartiallyPaid =>
      !isFullyPaid && entries.any((e) => e.cell.isPaid);

  List<_MonthEntry> get unpaidEntries =>
      entries.where((e) => !e.cell.isPaid).toList();

  double get dueAmount =>
      unpaidEntries.fold(0.0, (s, e) => s + e.cell.net);
  double get totalAmount =>
      entries.fold(0.0, (s, e) => s + e.cell.net);

  String get label {
    final parts = monthYear.split('-');
    if (parts.length != 2) return monthYear;
    final month = int.tryParse(parts[1]) ?? 1;
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${names[month]} ${parts[0]}';
  }
}

List<_MonthGroup> _buildMonthGroups(List<FeeRow> monthlyRows) {
  final Map<String, List<_MonthEntry>> byMonth = {};
  for (final row in monthlyRows) {
    for (final cell in row.cells) {
      byMonth.putIfAbsent(cell.monthYear, () => []).add(_MonthEntry(
            feeTypeId: row.feeTypeId,
            feeTypeName: row.feeTypeName,
            stoppageName: row.stoppageName,
            cell: cell,
          ));
    }
  }
  final sorted = byMonth.keys.toList()..sort();
  return sorted
      .map((k) => _MonthGroup(monthYear: k, entries: byMonth[k]!))
      .toList();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChildFeesScreen extends ConsumerWidget {
  const ChildFeesScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(parentAcademicYearsProvider);
    final effectiveYearId = ref.watch(effectiveParentYearIdProvider);
    final feeAsync = ref.watch(parentChildMatrixProvider(childId));
    final currency = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Fee Details'),
        centerTitle: false,
        actions: [
          yearsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (years) => years.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveYearId,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onChanged: (id) => ref
                            .read(selectedParentYearIdProvider.notifier)
                            .state = id,
                        items: years
                            .map((y) => DropdownMenuItem(
                                  value: y.id,
                                  child: Text(y.name,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: feeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(parentChildMatrixProvider(childId)),
        ),
        data: (matrix) {
          if (matrix == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _FeeBody(
            matrix: matrix,
            currency: currency,
            childId: childId,
          );
        },
      ),
    );
  }
}

// ── Body (stateful — owns selection + Razorpay) ───────────────────────────────

class _FeeBody extends ConsumerStatefulWidget {
  const _FeeBody({
    required this.matrix,
    required this.currency,
    required this.childId,
  });

  final FeeMatrixData matrix;
  final NumberFormat currency;
  final String childId;

  @override
  ConsumerState<_FeeBody> createState() => _FeeBodyState();
}

class _FeeBodyState extends ConsumerState<_FeeBody> {
  final Set<String> _selectedMonths = {};
  final Set<String> _selectedOneTimeIds = {};
  late final Razorpay _razorpay;
  bool _paying = false;
  String? _pendingPaymentId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  List<_MonthGroup> get _monthGroups {
    final monthly = widget.matrix.rows.where((r) => !r.isOneTime).toList();
    return _buildMonthGroups(monthly);
  }

  double get _selectedTotal {
    final monthsTotal = _monthGroups
        .where((g) => _selectedMonths.contains(g.monthYear))
        .fold(0.0, (s, g) => s + g.dueAmount);
    final oneTimeTotal = widget.matrix.rows
        .where((r) => r.isOneTime && _selectedOneTimeIds.contains(r.feeTypeId))
        .fold(0.0, (s, r) =>
            s + (r.cells.isNotEmpty ? r.cells.first.net : 0.0));
    return monthsTotal + oneTimeTotal;
  }

  int get _selectedCount =>
      _selectedMonths.length + _selectedOneTimeIds.length;

  String get _selectionDescription {
    final m = _selectedMonths.length;
    final o = _selectedOneTimeIds.length;
    if (m > 0 && o > 0) return '${m + o} items selected';
    if (m > 0) return '$m month${m > 1 ? 's' : ''} selected';
    return '$o fee${o > 1 ? 's' : ''} selected';
  }

  Future<void> _startPayment() async {
    if (_selectedCount == 0) return;
    setState(() => _paying = true);

    final items = <SelectedPaymentItem>[];

    // Monthly items
    for (final group in _monthGroups) {
      if (!_selectedMonths.contains(group.monthYear)) continue;
      for (final entry in group.unpaidEntries) {
        items.add(SelectedPaymentItem(
          feeTypeId: entry.feeTypeId,
          feeTypeName: entry.feeTypeName,
          monthYear: group.monthYear,
          stoppageName: entry.stoppageName,
          amountCharged: entry.cell.gross,
          concessionAmount: entry.cell.concession,
          lateFeeAmount: entry.cell.lateFee,
          amountPaid: entry.cell.net,
        ));
      }
    }

    // One-time items
    for (final row in widget.matrix.rows) {
      if (!row.isOneTime || !_selectedOneTimeIds.contains(row.feeTypeId)) {
        continue;
      }
      if (row.cells.isEmpty) continue;
      final cell = row.cells.first;
      items.add(SelectedPaymentItem(
        feeTypeId: row.feeTypeId,
        feeTypeName: row.feeTypeName,
        monthYear: cell.monthYear,
        stoppageName: row.stoppageName,
        amountCharged: cell.gross,
        concessionAmount: cell.concession,
        lateFeeAmount: cell.lateFee,
        amountPaid: cell.net,
      ));
    }

    try {
      final repo = ref.read(parentRepositoryProvider);
      final order = await repo.createPaymentOrder(
        studentId: widget.matrix.studentId,
        academicYearId: widget.matrix.academicYearId,
        items: items,
      );
      _pendingPaymentId = order.paymentId;
      _razorpay.open({
        'key': order.key,
        'amount': order.amount,
        'order_id': order.orderId,
        'currency': order.currency,
        'name': 'School Fee Payment',
        'description': _selectionDescription,
        'retry': {'enabled': false},
        'send_sms_hash': true,
      });
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create order: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _onSuccess(PaymentSuccessResponse response) async {
    final paymentId = _pendingPaymentId;
    if (paymentId == null) return;
    try {
      final repo = ref.read(parentRepositoryProvider);
      await repo.verifyPayment(
        paymentId: paymentId,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (mounted) {
        setState(() {
          _selectedMonths.clear();
          _selectedOneTimeIds.clear();
          _paying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment successful!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ));
        ref.invalidate(parentChildMatrixProvider(widget.childId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment received but verification failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _onError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _paying = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.message ?? 'Payment failed'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red,
    ));
  }

  void _onWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _paying = false);
  }

  void _toggleMonth(String monthYear) {
    setState(() {
      if (_selectedMonths.contains(monthYear)) {
        _selectedMonths.remove(monthYear);
      } else {
        _selectedMonths.add(monthYear);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final matrix = widget.matrix;
    final currency = widget.currency;
    final oneTime = matrix.rows.where((r) => r.isOneTime).toList();
    final monthGroups = _monthGroups;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, _selectedCount > 0 ? 100 : 32),
          children: [
            // Student chip
            _StudentChip(matrix: matrix),
            const SizedBox(height: 16),

            // Outstanding hero
            _OutstandingCard(matrix: matrix, currency: currency),
            const SizedBox(height: 20),

            // ── One-Time / Annual ────────────────────────────────────────
            if (oneTime.isNotEmpty) ...[
              Row(
                children: [
                  const Expanded(
                      child: _SectionHeader(label: 'Annual / One-Time Fees')),
                  if (oneTime.any(
                      (r) => r.cells.isNotEmpty && !r.cells.first.isPaid))
                    TextButton(
                      onPressed: () {
                        setState(() {
                          final allUnpaidIds = oneTime
                              .where((r) =>
                                  r.cells.isNotEmpty && !r.cells.first.isPaid)
                              .map((r) => r.feeTypeId)
                              .toSet();
                          if (_selectedOneTimeIds.containsAll(allUnpaidIds)) {
                            _selectedOneTimeIds.clear();
                          } else {
                            _selectedOneTimeIds.addAll(allUnpaidIds);
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(
                        _selectedOneTimeIds.length ==
                                oneTime
                                    .where((r) =>
                                        r.cells.isNotEmpty &&
                                        !r.cells.first.isPaid)
                                    .length
                            ? 'Deselect all'
                            : 'Select all due',
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...oneTime.map((row) => _OneTimeFeeCard(
                    row: row,
                    currency: currency,
                    isSelected: _selectedOneTimeIds.contains(row.feeTypeId),
                    onToggle:
                        (row.cells.isNotEmpty && !row.cells.first.isPaid)
                            ? () => setState(() {
                                  if (_selectedOneTimeIds
                                      .contains(row.feeTypeId)) {
                                    _selectedOneTimeIds.remove(row.feeTypeId);
                                  } else {
                                    _selectedOneTimeIds.add(row.feeTypeId);
                                  }
                                })
                            : null,
                  )),
              const SizedBox(height: 20),
            ],

            // ── Combined Monthly ─────────────────────────────────────────
            if (monthGroups.isNotEmpty) ...[
              Row(
                children: [
                  const Expanded(
                      child: _SectionHeader(label: 'Monthly Fees')),
                  if (monthGroups.any((g) => !g.isFullyPaid))
                    TextButton(
                      onPressed: () {
                        setState(() {
                          final allUnpaid = monthGroups
                              .where((g) => !g.isFullyPaid)
                              .map((g) => g.monthYear)
                              .toSet();
                          if (_selectedMonths.containsAll(allUnpaid)) {
                            _selectedMonths.clear();
                          } else {
                            _selectedMonths.addAll(allUnpaid);
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(
                        _selectedMonths.length ==
                                monthGroups
                                    .where((g) => !g.isFullyPaid)
                                    .length
                            ? 'Deselect all'
                            : 'Select all due',
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...monthGroups.map((group) => _MonthGroupCard(
                    group: group,
                    currency: currency,
                    isSelected: _selectedMonths.contains(group.monthYear),
                    onToggle: group.isFullyPaid
                        ? null
                        : () => _toggleMonth(group.monthYear),
                  )),
            ],
          ],
        ),

        // ── Sticky Pay Bar ───────────────────────────────────────────────
        if (_selectedCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton(
                    onPressed: _paying ? null : _startPayment,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _paying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectionDescription,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70),
                              ),
                              Text(
                                'Pay ${currency.format(_selectedTotal)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Student Chip ──────────────────────────────────────────────────────────────

class _StudentChip extends StatelessWidget {
  const _StudentChip({required this.matrix});
  final FeeMatrixData matrix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0x1A7C3AED),
            radius: 20,
            child: Icon(Icons.person, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(matrix.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${matrix.className} ${matrix.section} · ${matrix.admissionNumber}',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              matrix.academicYearName,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Outstanding Hero Card ─────────────────────────────────────────────────────

class _OutstandingCard extends StatelessWidget {
  const _OutstandingCard({required this.matrix, required this.currency});

  final FeeMatrixData matrix;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final hasOutstanding = matrix.totalOutstanding > 0;
    final gradientColors = hasOutstanding
        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
        : [const Color(0xFF22C55E), const Color(0xFF16A34A)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                hasOutstanding ? 'Amount Due' : 'All Clear',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(matrix.totalOutstanding),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                    label: 'Total',
                    value: currency.format(matrix.totalNet)),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _HeroStat(
                    label: 'Paid',
                    value: currency.format(matrix.totalPaid),
                    align: TextAlign.center),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _HeroStat(
                    label: 'Outstanding',
                    value: currency.format(matrix.totalOutstanding),
                    align: TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(
      {required this.label,
      required this.value,
      this.align = TextAlign.left});

  final String label;
  final String value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.left
          ? CrossAxisAlignment.start
          : align == TextAlign.right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center,
      children: [
        Text(value,
            textAlign: align,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            textAlign: align,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Combined Month Group Card ─────────────────────────────────────────────────

class _MonthGroupCard extends StatefulWidget {
  const _MonthGroupCard({
    required this.group,
    required this.currency,
    required this.isSelected,
    this.onToggle,
  });

  final _MonthGroup group;
  final NumberFormat currency;
  final bool isSelected;
  final VoidCallback? onToggle;

  @override
  State<_MonthGroupCard> createState() => _MonthGroupCardState();
}

class _MonthGroupCardState extends State<_MonthGroupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final group = widget.group;
    final currency = widget.currency;
    final isSelected = widget.isSelected;

    Color borderColor;
    Color bgColor;
    if (group.isFullyPaid) {
      borderColor = Colors.green.withValues(alpha: 0.3);
      bgColor = Colors.green.withValues(alpha: 0.04);
    } else if (isSelected) {
      borderColor = cs.primary.withValues(alpha: 0.6);
      bgColor = cs.primaryContainer.withValues(alpha: 0.35);
    } else {
      borderColor = cs.outlineVariant.withValues(alpha: 0.5);
      bgColor = cs.surface;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    child: group.isFullyPaid
                        ? const Center(
                            child: Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 22),
                          )
                        : Checkbox(
                            value: isSelected,
                            onChanged: widget.onToggle != null
                                ? (_) => widget.onToggle!()
                                : null,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                          ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(group: group),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          group.entries
                              .map((e) => e.stoppageName != null
                                  ? '${e.feeTypeName} (${e.stoppageName})'
                                  : e.feeTypeName)
                              .join(' · '),
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        group.isFullyPaid
                            ? currency.format(group.totalAmount)
                            : currency.format(group.dueAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: group.isFullyPaid
                              ? Colors.green
                              : isSelected
                                  ? cs.primary
                                  : cs.onSurface,
                        ),
                      ),
                      Text(
                        group.isFullyPaid ? 'paid' : 'due',
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded breakdown ───────────────────────────────────────
          if (_expanded) ...[
            Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
                indent: 16,
                endIndent: 16),
            ...group.entries.map((entry) =>
                _FeeLineRow(entry: entry, currency: currency)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.group});
  final _MonthGroup group;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;

    if (group.isFullyPaid) {
      label = 'Paid';
      bg = Colors.green.withValues(alpha: 0.12);
      fg = Colors.green.shade700;
    } else if (group.isPartiallyPaid) {
      label = 'Partial';
      bg = Colors.blue.withValues(alpha: 0.1);
      fg = Colors.blue.shade700;
    } else {
      label = 'Due';
      bg = Colors.orange.withValues(alpha: 0.12);
      fg = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _FeeLineRow extends StatelessWidget {
  const _FeeLineRow({required this.entry, required this.currency});

  final _MonthEntry entry;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cell = entry.cell;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: cell.isPaid ? Colors.green : cs.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.stoppageName != null
                      ? '${entry.feeTypeName} · ${entry.stoppageName}'
                      : entry.feeTypeName,
                  style: const TextStyle(fontSize: 13),
                ),
                if (cell.concession > 0)
                  Text(
                    '-${currency.format(cell.concession)} concession',
                    style:
                        TextStyle(fontSize: 11, color: Colors.green.shade600),
                  ),
                if (cell.lateFee > 0)
                  Text(
                    '+${currency.format(cell.lateFee)} late fee',
                    style:
                        TextStyle(fontSize: 11, color: Colors.red.shade400),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(cell.net),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cell.isPaid ? Colors.green : cs.onSurface,
                ),
              ),
              if (cell.isPaid && cell.receiptNumber != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_outlined,
                        size: 10, color: cs.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(cell.receiptNumber!,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant)),
                  ],
                ),
              if (!cell.isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Unpaid',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── One-Time Fee Card ─────────────────────────────────────────────────────────

class _OneTimeFeeCard extends StatelessWidget {
  const _OneTimeFeeCard({
    required this.row,
    required this.currency,
    required this.isSelected,
    this.onToggle,
  });

  final FeeRow row;
  final NumberFormat currency;
  final bool isSelected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cell = row.cells.isNotEmpty ? row.cells.first : null;
    final isPaid = cell?.isPaid ?? false;
    final amount = cell?.net ?? 0.0;

    Color borderColor;
    Color bgColor;
    if (isPaid) {
      borderColor = Colors.green.withValues(alpha: 0.3);
      bgColor = Colors.green.withValues(alpha: 0.04);
    } else if (isSelected) {
      borderColor = cs.primary.withValues(alpha: 0.6);
      bgColor = cs.primaryContainer.withValues(alpha: 0.35);
    } else {
      borderColor = cs.outlineVariant.withValues(alpha: 0.5);
      bgColor = cs.surface;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: isPaid
                      ? const Center(
                          child: Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 22),
                        )
                      : Checkbox(
                          value: isSelected,
                          onChanged:
                              onToggle != null ? (_) => onToggle!() : null,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.feeTypeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid ? 'Paid' : 'Due',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isPaid
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(amount),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isPaid
                              ? Colors.green
                              : isSelected
                                  ? cs.primary
                                  : cs.onSurface),
                    ),
                    if (cell != null && cell.concession > 0)
                      Text(
                        '-${currency.format(cell.concession)} off',
                        style: TextStyle(
                            fontSize: 11, color: Colors.green.shade600),
                      ),
                    if (cell != null && cell.lateFee > 0)
                      Text(
                        '+${currency.format(cell.lateFee)} late',
                        style: TextStyle(
                            fontSize: 11, color: Colors.red.shade400),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            const Text('Failed to load fee details',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant),
                maxLines: 3),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
