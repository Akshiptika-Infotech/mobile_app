import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/utils/responsive_utils.dart';
import 'package:mobile_app/features/admin/domain/fee_model.dart';
import 'package:mobile_app/features/admin/providers/fee_provider.dart';

class FeeCollectionScreen extends ConsumerStatefulWidget {
  const FeeCollectionScreen({super.key});

  @override
  ConsumerState<FeeCollectionScreen> createState() =>
      _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends ConsumerState<FeeCollectionScreen> {
  final _searchCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  String _paymentMode = 'Cash';
  DateTime _paymentDate = DateTime.now();

  static const _paymentModes = ['Cash', 'Online', 'Cheque', 'UPI'];
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _receiptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feeCollectionProvider);

    return PopScope(
      canPop: state.step == FeeCollectionStep.search,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(feeCollectionProvider.notifier).goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fee Collection'),
          leading: state.step != FeeCollectionStep.search
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      ref.read(feeCollectionProvider.notifier).goBack(),
                )
              : null,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              ResponsiveUtils.isSmallScreen(context) ? 56 : 72,
            ),
            child: _StepIndicator(
              steps: const ['Search', 'Matrix', 'Payment', 'Receipt'],
              current: state.step.index,
              isCompact: ResponsiveUtils.isSmallScreen(context),
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: KeyedSubtree(
            key: ValueKey(state.step),
            child: switch (state.step) {
              FeeCollectionStep.search => _SearchStep(
                  ctrl: _searchCtrl,
                  state: state,
                  onSearch: (q) =>
                      ref.read(feeCollectionProvider.notifier).search(q),
                  onSelect: (s) =>
                      ref.read(feeCollectionProvider.notifier).selectStudent(s),
                ),
              FeeCollectionStep.matrix => _MatrixStep(
                  state: state,
                  fmt: _fmt,
                  onToggle: (m) =>
                      ref.read(feeCollectionProvider.notifier).toggleMonth(m),
                  onProceed: state.selectedMonths.isEmpty
                      ? null
                      : () => ref
                          .read(feeCollectionProvider.notifier)
                          .proceedToPayment(),
                ),
              FeeCollectionStep.payment => _PaymentStep(
                  state: state,
                  fmt: _fmt,
                  receiptCtrl: _receiptCtrl,
                  paymentMode: _paymentMode,
                  paymentDate: _paymentDate,
                  paymentModes: _paymentModes,
                  onModeChanged: (v) =>
                      setState(() => _paymentMode = v ?? 'Cash'),
                  onDateChanged: (d) =>
                      setState(() => _paymentDate = d),
                  onSubmit: () =>
                      ref.read(feeCollectionProvider.notifier).submitPayment(
                            paymentMode: _paymentMode,
                            receiptNumber: _receiptCtrl.text.trim(),
                            date: _paymentDate
                                .toIso8601String()
                                .split('T')
                                .first,
                          ),
                ),
              FeeCollectionStep.receipt => _ReceiptStep(
                  state: state,
                  fmt: _fmt,
                  onDone: () =>
                      ref.read(feeCollectionProvider.notifier).reset(),
                ),
            },
          ),
        ),
      ),
    );
  }
}

// ── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.steps,
    required this.current,
    this.isCompact = false,
  });
  final List<String> steps;
  final int current;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 6 : 8,
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = (i - 1) ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIdx < current
                    ? cs.primary
                    : cs.outlineVariant,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final done = stepIdx < current;
          final active = stepIdx == current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isCompact ? 20 : 24,
                height: isCompact ? 20 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? cs.primary : cs.surfaceContainerHighest,
                  border: Border.all(
                    color: done || active ? cs.primary : cs.outline,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: done
                      ? Icon(Icons.check, size: isCompact ? 10 : 14, color: cs.onPrimary)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: isCompact ? 9 : 11,
                            fontWeight: FontWeight.bold,
                            color: active ? cs.onPrimary : cs.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              if (!isCompact) const SizedBox(height: 4),
              if (!isCompact)
                Text(
                  steps[stepIdx],
                  style: TextStyle(
                    fontSize: 10,
                    color: active ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Step 1: Search ───────────────────────────────────────────────────────────

class _SearchStep extends StatelessWidget {
  const _SearchStep({
    required this.ctrl,
    required this.state,
    required this.onSearch,
    required this.onSelect,
  });

  final TextEditingController ctrl;
  final FeeCollectionState state;
  final ValueChanged<String> onSearch;
  final ValueChanged<FeeSearchResult> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSmall = ResponsiveUtils.isSmallScreen(context);
    final padding = isSmall ? 12.0 : 16.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by name or admission number…',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: state.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          iconSize: 20,
                          padding: const EdgeInsets.all(8),
                          onPressed: () {
                            ctrl.clear();
                            onSearch('');
                          },
                        )
                      : null,
              filled: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isSmall ? 10 : 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearch,
          ),
        ),
        if (state.error != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(state.error!,
                style: TextStyle(color: cs.error, fontSize: 12)),
          ),
        Expanded(
          child: state.searchResults.isEmpty && !state.isSearching
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search,
                          size: isSmall ? 48 : 64,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Search for a student to collect fee',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  itemCount: state.searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = state.searchResults[i];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 4 : 8,
                        vertical: isSmall ? 2 : 4,
                      ),
                      leading: CircleAvatar(
                        radius: isSmall ? 16 : 20,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          s.initials,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmall ? 12 : 14,
                          ),
                        ),
                      ),
                      title: Text(
                        s.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmall ? 13 : 15,
                        ),
                      ),
                      subtitle: Text(
                        '${s.className}-${s.section} · #${s.admissionNumber}',
                        style: TextStyle(fontSize: isSmall ? 11 : 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => onSelect(s),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Step 2: Matrix ───────────────────────────────────────────────────────────

class _MatrixStep extends StatelessWidget {
  const _MatrixStep({
    required this.state,
    required this.fmt,
    required this.onToggle,
    required this.onProceed,
  });

  final FeeCollectionState state;
  final NumberFormat fmt;
  final ValueChanged<FeeMonth> onToggle;
  final VoidCallback? onProceed;

  bool _isSelected(FeeMonth m) => state.selectedMonths
      .any((s) => s.month == m.month && s.feeType == m.feeType);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final student = state.selectedStudent!;

    if (state.isLoadingMatrix) {
      return const Center(child: CircularProgressIndicator());
    }

    final matrix = state.feeMatrix;
    if (matrix == null) {
      return Center(
        child: Text(state.error ?? 'No fee data found.',
            style: TextStyle(color: cs.error)),
      );
    }

    // Group by month
    final Map<String, List<FeeMonth>> byMonth = {};
    for (final f in matrix.feeMatrix) {
      byMonth.putIfAbsent(f.month, () => []).add(f);
    }

    return Column(
      children: [
        // Student header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primary,
                child: Text(student.initials,
                    style: TextStyle(
                        color: cs.onPrimary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '${student.className}-${student.section} · #${student.admissionNumber}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onPrimaryContainer)),
                  ],
                ),
              ),
              if (state.selectedMonths.isNotEmpty)
                Chip(
                  label: Text(fmt.format(state.totalAmount)),
                  backgroundColor: cs.primary,
                  labelStyle: TextStyle(
                      color: cs.onPrimary, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),

        // Matrix list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: byMonth.entries.map((entry) {
              final monthFees = entry.value;
              final hasDue = monthFees.any((f) => f.isDue);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const Spacer(),
                          if (!hasDue)
                            Chip(
                              label: const Text('All Paid'),
                              backgroundColor: Colors.green.shade100,
                              labelStyle:
                                  TextStyle(color: Colors.green.shade800),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...monthFees.map((fee) => _FeeRow(
                            fee: fee,
                            selected: _isSelected(fee),
                            fmt: fmt,
                            onTap: fee.isDue ? () => onToggle(fee) : null,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Proceed button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: onProceed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                state.selectedMonths.isEmpty
                    ? 'Select months to proceed'
                    : 'Proceed · ${fmt.format(state.totalAmount)}',
              ),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.fee,
    required this.selected,
    required this.fmt,
    required this.onTap,
  });

  final FeeMonth fee;
  final bool selected;
  final NumberFormat fmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color statusColor;
    String statusLabel;
    if (fee.isPaid) {
      statusColor = Colors.green;
      statusLabel = 'Paid';
    } else if (fee.isDue) {
      statusColor = cs.error;
      statusLabel = 'Due';
    } else {
      statusColor = cs.onSurfaceVariant;
      statusLabel = 'N/A';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : fee.isDue
                  ? cs.errorContainer.withValues(alpha: 0.3)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (fee.isDue)
              Icon(
                selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 18,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              )
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(fee.feeType,
                  style: const TextStyle(fontSize: 13)),
            ),
            Text(fmt.format(fee.amount),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 3: Payment form ─────────────────────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.state,
    required this.fmt,
    required this.receiptCtrl,
    required this.paymentMode,
    required this.paymentDate,
    required this.paymentModes,
    required this.onModeChanged,
    required this.onDateChanged,
    required this.onSubmit,
  });

  final FeeCollectionState state;
  final NumberFormat fmt;
  final TextEditingController receiptCtrl;
  final String paymentMode;
  final DateTime paymentDate;
  final List<String> paymentModes;
  final ValueChanged<String?> onModeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSmall = ResponsiveUtils.isSmallScreen(context);
    final padding = isSmall ? 12.0 : 16.0;

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        // Summary card
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Summary',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Student', style: TextStyle(color: cs.onPrimaryContainer)),
                    const Spacer(),
                    Text(state.selectedStudent!.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Months (${state.selectedMonths.length})',
                        style: TextStyle(color: cs.onPrimaryContainer)),
                    const Spacer(),
                    Text(
                      state.selectedMonths
                          .map((m) => m.month)
                          .toSet()
                          .join(', '),
                      style: TextStyle(color: cs.onPrimaryContainer),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: cs.onPrimaryContainer)),
                    const Spacer(),
                    Text(fmt.format(state.totalAmount),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: cs.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Payment mode
        DropdownButtonFormField<String>(
          initialValue: paymentMode,
          decoration: const InputDecoration(
            labelText: 'Payment Mode',
            border: OutlineInputBorder(),
            filled: true,
            prefixIcon: Icon(Icons.payment_outlined),
          ),
          items: paymentModes
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: onModeChanged,
        ),
        const SizedBox(height: 12),

        // Receipt number
        TextField(
          controller: receiptCtrl,
          decoration: const InputDecoration(
            labelText: 'Receipt Number (optional)',
            border: OutlineInputBorder(),
            filled: true,
            prefixIcon: Icon(Icons.receipt_outlined),
          ),
        ),
        const SizedBox(height: 12),

        // Date picker
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: paymentDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Payment Date',
              border: OutlineInputBorder(),
              filled: true,
              prefixIcon: Icon(Icons.calendar_today_outlined),
              suffixIcon: Icon(Icons.edit_calendar_outlined),
            ),
            child: Text(DateFormat('dd MMM yyyy').format(paymentDate)),
          ),
        ),
        const SizedBox(height: 28),

        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(state.error!,
                  style: TextStyle(color: cs.onErrorContainer)),
            ),
          ),

        FilledButton.icon(
          onPressed: state.isSubmitting ? null : onSubmit,
          icon: state.isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: Text(
              state.isSubmitting ? 'Processing…' : 'Confirm Payment'),
          style:
              FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }
}

// ── Step 4: Receipt ──────────────────────────────────────────────────────────

class _ReceiptStep extends StatelessWidget {
  const _ReceiptStep({
    required this.state,
    required this.fmt,
    required this.onDone,
  });

  final FeeCollectionState state;
  final NumberFormat fmt;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final receipt = state.receipt;
    if (receipt == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      size: 48, color: Colors.green.shade700),
                ),
                const SizedBox(height: 16),
                Text('Payment Successful!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Receipt #${receipt.receiptNumber}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                // Receipt card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _ReceiptRow('Student', receipt.studentName),
                        _ReceiptRow('Admission No.',
                            receipt.admissionNumber),
                        _ReceiptRow('Class',
                            '${receipt.className}-${receipt.section}'),
                        _ReceiptRow('Months',
                            receipt.months.join(', ')),
                        _ReceiptRow('Payment Mode', receipt.paymentMode),
                        _ReceiptRow('Date', receipt.date),
                        const Divider(),
                        Row(
                          children: [
                            const Text('Amount Paid',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const Spacer(),
                            Text(fmt.format(receipt.amount),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: cs.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Actions
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('PDF sharing coming in Phase M9')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Receipt PDF'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.add),
                  label: const Text('New Collection'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
