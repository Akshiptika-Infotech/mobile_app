import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/class_model.dart';
import 'package:mobile_app/features/admin/providers/academic_year_provider.dart';
import 'package:mobile_app/features/parent/data/parent_repository.dart';
import 'package:mobile_app/features/parent/domain/parent_receipt_model.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';
import 'package:mobile_app/features/parent/presentation/widgets/child_selector.dart';
import 'package:printing/printing.dart';

class ParentReceiptsScreen extends ConsumerWidget {
  const ParentReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final receiptsAsync = ref.watch(receiptsProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final selectedYear = ref.watch(selectedYearProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Receipts'),
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
                    child: DropdownButtonFormField<AcademicYear?>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Academic year',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<AcademicYear?>(
                            value: null, child: Text('All years')),
                        ...years.map(
                          (y) => DropdownMenuItem<AcademicYear?>(
                            value: y,
                            child: Text(
                                y.name + (y.isActive ? ' · Active' : '')),
                          ),
                        ),
                      ],
                      onChanged: (y) {
                        ref.read(selectedYearProvider.notifier).state = y;
                      },
                    ),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(receiptsProvider);
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: receiptsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$e', style: TextStyle(color: cs.error)),
                  ),
                ]),
                data: (page) {
                  if (page.collections.isEmpty) {
                    return ListView(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 64,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('No receipts yet',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ]);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: page.collections.length,
                    itemBuilder: (_, i) =>
                        _ReceiptCard(receipt: page.collections[i]),
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

class _ReceiptCard extends ConsumerStatefulWidget {
  const _ReceiptCard({required this.receipt});
  final ParentReceipt receipt;

  @override
  ConsumerState<_ReceiptCard> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends ConsumerState<_ReceiptCard> {
  bool _busy = false;

  Future<void> _viewPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = Uint8List.fromList(await ref
          .read(parentRepositoryProvider)
          .downloadReceiptPdf(widget.receipt.id));
      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = Uint8List.fromList(await ref
          .read(parentRepositoryProvider)
          .downloadReceiptPdf(widget.receipt.id));
      if (!mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Receipt-${widget.receipt.receiptNumber}.pdf',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = widget.receipt;
    final money = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.receipt_long_rounded,
                      color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt #${r.receiptNumber}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                          DateFormat('d MMM yyyy, h:mm a')
                              .format(r.collectedAt),
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text(money.format(r.totalAmount),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${r.studentName}'
              '${r.admissionNumber != null ? ' · ${r.admissionNumber}' : ''}'
              '${r.className != null ? ' · ${r.className}' : ''}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            if (r.isRevoked) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('REVOKED',
                    style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4)),
              ),
            ],
            if (r.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: r.items
                    .take(4)
                    .map((it) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${it.feeTypeName} · ${it.monthYear}',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _viewPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('View'),
                    style: _compactStyle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _sharePdf,
                    icon: _busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Share'),
                    style: _compactStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static final ButtonStyle _compactStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(0, 40)),
    padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
