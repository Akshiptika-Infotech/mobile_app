import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';
import 'package:mobile_app/features/admin/providers/academic_year_provider.dart';
import 'package:mobile_app/features/parent/data/parent_repository.dart';
import 'package:mobile_app/features/parent/domain/fee_matrix_model.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:mobile_app/features/parent/presentation/widgets/child_selector.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ParentFeesScreen extends ConsumerStatefulWidget {
  const ParentFeesScreen({super.key});

  @override
  ConsumerState<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends ConsumerState<ParentFeesScreen> {
  /// Selected unpaid cells, keyed by `feeTypeId-monthYear`.
  final Set<String> _selectedKeys = {};
  bool _payInFlight = false;
  Razorpay? _razorpay;
  String? _pendingPaymentId;

  String _cellKey(FeeRow row, FeeCell cell) =>
      '${row.feeTypeId}-${cell.monthYear}';

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Razorpay _ensureRazorpay() {
    final r = _razorpay ?? Razorpay();
    if (_razorpay == null) {
      r.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
      r.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
      r.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
      _razorpay = r;
    }
    return r;
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse resp) async {
    final messenger = ScaffoldMessenger.of(context);
    final paymentId = _pendingPaymentId;
    if (paymentId == null ||
        resp.orderId == null ||
        resp.paymentId == null ||
        resp.signature == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Payment received but verification data missing.')));
      setState(() => _payInFlight = false);
      return;
    }
    try {
      await ref.read(parentRepositoryProvider).verifyPayment(
            paymentId: paymentId,
            razorpayOrderId: resp.orderId!,
            razorpayPaymentId: resp.paymentId!,
            razorpaySignature: resp.signature!,
          );
      ref.invalidate(feeMatrixProvider);
      ref.invalidate(receiptsProvider);
      _selectedKeys.clear();
      messenger.showSnackBar(const SnackBar(
          content: Text('Payment successful. Receipt will appear shortly.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Verify failed: $e')));
    } finally {
      if (mounted) setState(() => _payInFlight = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse resp) {
    final msg = resp.message ?? 'Payment failed';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    setState(() => _payInFlight = false);
  }

  void _onExternalWallet(ExternalWalletResponse resp) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External wallet: ${resp.walletName}')));
  }

  /// Pays the currently selected items inside one specific category
  /// (`ONE_TIME` or `ANNUAL`). Each card owns its own Pay button so the
  /// parent can pay each category independently.
  Future<void> _paySelected(
      FeeMatrix matrix, String feeTypeCategory) async {
    final lines = <SelectedFeeLine>[];
    for (final row in matrix.rows) {
      if (row.feeTypeCategory != feeTypeCategory) continue;
      for (final cell in row.cells) {
        if (cell.isPaid) continue;
        if (!_selectedKeys.contains(_cellKey(row, cell))) continue;
        lines.add(_lineFor(row, cell));
      }
    }
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one fee line.')));
      return;
    }
    await _payLines(matrix, lines);
  }

  /// Pays all unpaid monthly+transport cells for a single [monthYear].
  Future<void> _payMonth(FeeMatrix matrix, String monthYear) async {
    final lines = <SelectedFeeLine>[];
    for (final row in matrix.rows) {
      if (!_isMonthlyOrTransport(row)) continue;
      for (final cell in row.cells) {
        if (cell.monthYear != monthYear) continue;
        if (cell.isPaid) continue;
        lines.add(_lineFor(row, cell));
      }
    }
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to pay for this month.')));
      return;
    }
    await _payLines(matrix, lines);
  }

  Future<void> _payLines(
      FeeMatrix matrix, List<SelectedFeeLine> lines) async {
    final messenger = ScaffoldMessenger.of(context);
    final profileName = ref.read(parentProfileProvider).value?.userName ?? '';
    final config = AppConfigScope.of(context);
    final appName = config.appName;
    final brandHex =
        '#${config.primaryColor.toARGB32().toRadixString(16).substring(2)}';
    setState(() => _payInFlight = true);
    try {
      final order =
          await ref.read(parentRepositoryProvider).createPaymentOrder(
                studentId: matrix.studentId,
                academicYearId: matrix.academicYearId,
                items: lines,
              );
      _pendingPaymentId = order.paymentId;
      _ensureRazorpay().open(<String, dynamic>{
        'key': order.key,
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': order.currency,
        'name': appName,
        'description': '${matrix.studentName} · ${matrix.academicYearName}',
        'prefill': {'name': profileName},
        'theme': {'color': brandHex},
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      if (mounted) setState(() => _payInFlight = false);
    }
  }

  static SelectedFeeLine _lineFor(FeeRow row, FeeCell cell) => SelectedFeeLine(
        feeTypeId: row.feeTypeId,
        feeTypeName: row.feeTypeName,
        monthYear: cell.monthYear,
        stoppageName: cell.stoppageName ?? row.stoppageName,
        amountCharged: cell.baseAmount,
        concessionAmount: cell.concessionAmount,
        lateFeeAmount: cell.lateFeeAmount,
        amountPaid: cell.amountDue,
      );

  static bool _isMonthlyOrTransport(FeeRow row) =>
      row.feeTypeCategory == 'MONTHLY' || row.feeTypeCategory == 'TRANSPORT';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final matrixAsync = ref.watch(feeMatrixProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final selectedYear = ref.watch(selectedYearProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Fees'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: ChildSelector(),
          ),
          yearsAsync.when(
            data: (years) => years.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DropdownButtonFormField<AcademicYear>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Academic year',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      items: years
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.name +
                                    (y.isActive ? ' · Active' : '')),
                              ))
                          .toList(),
                      onChanged: (y) {
                        if (y != null) {
                          ref
                              .read(selectedYearProvider.notifier)
                              .state = y;
                        }
                      },
                    ),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text('$e', style: TextStyle(color: cs.error)),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(feeMatrixProvider);
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: matrixAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$e', style: TextStyle(color: cs.error)),
                  ),
                ]),
                data: (m) {
                  if (m == null) {
                    return ListView(children: const [
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 80, 24, 24),
                        child: Center(
                            child: Text('Pick a child to view their fees.')),
                      ),
                    ]);
                  }
                  if (m.rows.isEmpty) {
                    return ListView(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        child: Center(
                          child: Text(
                            'No fee structure configured for ${m.studentName} this year.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ]);
                  }
                  return _MatrixBody(
                    matrix: m,
                    selectedKeys: _selectedKeys,
                    payInFlight: _payInFlight,
                    toggle: (row, cell) => setState(() {
                      final key = _cellKey(row, cell);
                      if (!_selectedKeys.add(key)) {
                        _selectedKeys.remove(key);
                      }
                    }),
                    onPayCategory: (category) =>
                        _paySelected(m, category),
                    onPayMonth: (monthYear) => _payMonth(m, monthYear),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixBody extends StatelessWidget {
  const _MatrixBody({
    required this.matrix,
    required this.selectedKeys,
    required this.payInFlight,
    required this.toggle,
    required this.onPayCategory,
    required this.onPayMonth,
  });

  final FeeMatrix matrix;
  final Set<String> selectedKeys;
  final bool payInFlight;
  final void Function(FeeRow row, FeeCell cell) toggle;

  /// Pays selected items within one specific [feeTypeCategory] —
  /// either `ONE_TIME` or `ANNUAL`.
  final void Function(String feeTypeCategory) onPayCategory;
  final void Function(String monthYear) onPayMonth;

  static bool _isMonthlyOrTransport(FeeRow r) =>
      r.feeTypeCategory == 'MONTHLY' || r.feeTypeCategory == 'TRANSPORT';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final oneTimeRows = matrix.rows
        .where((r) => r.feeTypeCategory == 'ONE_TIME')
        .toList();
    final annualRows = matrix.rows
        .where((r) => r.feeTypeCategory == 'ANNUAL')
        .toList();
    final monthlyRows = matrix.rows.where(_isMonthlyOrTransport).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Summary card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding',
                        style: TextStyle(
                            color: cs.onPrimaryContainer
                                .withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    Text(
                      money.format(matrix.totalDue),
                      style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paid · ${money.format(matrix.totalPaid)}',
                      style: TextStyle(
                          color: cs.onPrimaryContainer
                              .withValues(alpha: 0.85),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.account_balance_wallet_rounded,
                  color: cs.onPrimaryContainer, size: 36),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── One-Time fees card (only if there are ONE_TIME rows) ──────
        if (oneTimeRows.isNotEmpty)
          _SelectableFeeCard(
            title: 'One-Time Fees',
            icon: Icons.bolt_rounded,
            rows: oneTimeRows,
            money: money,
            selectedKeys: selectedKeys,
            toggle: toggle,
            payInFlight: payInFlight,
            onPay: () => onPayCategory('ONE_TIME'),
          ),

        if (oneTimeRows.isNotEmpty && annualRows.isNotEmpty)
          const SizedBox(height: 16),

        // ── Annual fees card (only if there are ANNUAL rows) ──────────
        if (annualRows.isNotEmpty)
          _SelectableFeeCard(
            title: 'Annual Fees',
            icon: Icons.event_note_rounded,
            rows: annualRows,
            money: money,
            selectedKeys: selectedKeys,
            toggle: toggle,
            payInFlight: payInFlight,
            onPay: () => onPayCategory('ANNUAL'),
          ),

        // ── Monthly Tuition + Transport bundle card ───────────────────
        if (monthlyRows.isNotEmpty) ...[
          const SizedBox(height: 16),
          _MonthlyBundleCard(
            rows: monthlyRows,
            money: money,
            payInFlight: payInFlight,
            onPayMonth: onPayMonth,
          ),
        ],
      ],
    );
  }
}

/// Card that lists every fee row passed in (filtered upstream by category).
/// Each unpaid item is tappable to toggle selection; the footer shows the
/// running selection total and a Pay button that opens Razorpay for just
/// the items inside this card.
class _SelectableFeeCard extends StatelessWidget {
  const _SelectableFeeCard({
    required this.title,
    required this.icon,
    required this.rows,
    required this.money,
    required this.selectedKeys,
    required this.toggle,
    required this.payInFlight,
    required this.onPay,
  });

  final String title;
  final IconData icon;
  final List<FeeRow> rows;
  final NumberFormat money;
  final Set<String> selectedKeys;
  final void Function(FeeRow row, FeeCell cell) toggle;
  final bool payInFlight;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Tally selection scoped to this card's rows only.
    var selectedTotal = 0.0;
    var selectedCount = 0;
    final tiles = <Widget>[];
    for (final r in rows) {
      for (final c in r.cells) {
        final key = '${r.feeTypeId}-${c.monthYear}';
        final isSelected = selectedKeys.contains(key);
        if (isSelected && !c.isPaid) {
          selectedTotal += c.amountDue;
          selectedCount++;
        }
        tiles.add(_OneTimeRow(
          row: r,
          cell: c,
          money: money,
          isSelected: isSelected,
          onTap: () => toggle(r, c),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(
              children: [
                Icon(icon, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text('Tap to select, then Pay.',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant)),
          ),
          const Divider(height: 1),
          if (tiles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nothing here.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            )
          else
            ...tiles,
          if (tiles.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$selectedCount selected',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant)),
                        Text(
                          money.format(selectedTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: (selectedTotal <= 0 || payInFlight)
                          ? null
                          : onPay,
                      icon: payInFlight
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.payments_rounded, size: 18),
                      label: const Text('Pay'),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OneTimeRow extends StatelessWidget {
  const _OneTimeRow({
    required this.row,
    required this.cell,
    required this.money,
    required this.isSelected,
    required this.onTap,
  });
  final FeeRow row;
  final FeeCell cell;
  final NumberFormat money;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = cell.isPaid;
    return InkWell(
      onTap: disabled ? null : onTap,
      child: Container(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (disabled)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 22)
            else
              Icon(
                isSelected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                size: 22,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.feeTypeName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    row.feeTypeCategory.replaceAll('_', ' '),
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3),
                  ),
                  if (disabled && cell.receiptNumber != null)
                    Text('Receipt #${cell.receiptNumber}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Text(
              money.format(cell.amountDue),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: disabled ? cs.onSurfaceVariant : cs.onSurface,
                decoration: disabled ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bundles MONTHLY + TRANSPORT rows by month. Each row shows the combined
/// Tuition + Transport amount and is tappable — tap opens Razorpay for
/// just that month's combined amount.
class _MonthlyBundleCard extends StatelessWidget {
  const _MonthlyBundleCard({
    required this.rows,
    required this.money,
    required this.payInFlight,
    required this.onPayMonth,
  });

  final List<FeeRow> rows;
  final NumberFormat money;
  final bool payInFlight;
  final void Function(String monthYear) onPayMonth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Aggregate per monthYear preserving the natural order produced by
    // the backend (Apr through Mar).
    final order = <String>[];
    final perMonth = <String, _MonthAggregate>{};
    for (final r in rows) {
      for (final c in r.cells) {
        final agg = perMonth.putIfAbsent(c.monthYear, () {
          order.add(c.monthYear);
          return _MonthAggregate(c.monthYear);
        });
        agg.add(r, c);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    color: cs.primary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Monthly Fees · Tuition + Transport',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text('Tap a month to pay through Razorpay.',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant)),
          ),
          const Divider(height: 1),
          for (var i = 0; i < order.length; i++) ...[
            _MonthlyBundleRow(
              aggregate: perMonth[order[i]]!,
              money: money,
              payInFlight: payInFlight,
              onTap: () => onPayMonth(order[i]),
            ),
            if (i < order.length - 1)
              const Divider(height: 1, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

class _MonthAggregate {
  _MonthAggregate(this.monthYear);
  final String monthYear;
  double total = 0;
  bool allPaid = true;
  int unpaidCells = 0;

  void add(FeeRow _, FeeCell cell) {
    if (!cell.isPaid) {
      total += cell.amountDue;
      allPaid = false;
      unpaidCells++;
    }
  }
}

class _MonthlyBundleRow extends StatelessWidget {
  const _MonthlyBundleRow({
    required this.aggregate,
    required this.money,
    required this.payInFlight,
    required this.onTap,
  });
  final _MonthAggregate aggregate;
  final NumberFormat money;
  final bool payInFlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final paid = aggregate.allPaid;
    final disabled = paid || payInFlight;
    return InkWell(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: paid
                    ? const Color(0xFF10B981).withValues(alpha: 0.14)
                    : cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                paid
                    ? Icons.check_circle_rounded
                    : Icons.event_rounded,
                color: paid ? const Color(0xFF10B981) : cs.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatMonth(aggregate.monthYear),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(
                    paid
                        ? 'Paid'
                        : '${aggregate.unpaidCells} item${aggregate.unpaidCells == 1 ? '' : 's'} due',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: paid ? FontWeight.w600 : FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money.format(aggregate.total),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: paid ? cs.onSurfaceVariant : cs.onSurface,
                    decoration: paid ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!paid)
                  Text('Tap to pay',
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.primary,
                          fontWeight: FontWeight.w700)),
              ],
            ),
            if (!paid)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child:
                    Icon(Icons.chevron_right_rounded, color: cs.primary),
              ),
          ],
        ),
      ),
    );
  }

  /// Backend monthYear is `YYYY-MM` (e.g. `2026-04`). Render as `Apr 2026`.
  static String _formatMonth(String monthYear) {
    final parts = monthYear.split('-');
    if (parts.length != 2) return monthYear;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return monthYear;
    }
    return DateFormat('MMM yyyy').format(DateTime(year, month));
  }
}
