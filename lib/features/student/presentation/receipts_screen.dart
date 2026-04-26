import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/student/domain/student_portal_model.dart';
import 'package:mobile_app/features/student/providers/student_portal_provider.dart';

class StudentReceiptsScreen extends ConsumerWidget {
  const StudentReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(studentReceiptsProvider);
    final currency = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Receipts'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(studentReceiptsProvider),
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                const Text('Failed to load receipts',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                    maxLines: 3),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(studentReceiptsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (receipts) {
          if (receipts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No receipts found',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: receipts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _ReceiptCard(receipt: receipts[index], currency: currency),
          );
        },
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.currency});

  final StudentReceipt receipt;
  final NumberFormat currency;

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRevoked = receipt.isRevoked;
    final accentColor =
        isRevoked ? Colors.grey : const Color(0xFFF59E0B);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.15),
          child: Icon(
            isRevoked ? Icons.cancel_outlined : Icons.receipt_long,
            color: accentColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                receipt.receiptNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (isRevoked)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Revoked',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        subtitle: Text(
          '${_formatDate(receipt.collectedAt)} · ${receipt.academicYearName}',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Text(
          currency.format(receipt.total),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRevoked ? Colors.grey : Colors.green,
              fontSize: 14,
              decoration: isRevoked ? TextDecoration.lineThrough : null),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.payment, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(receipt.paymentMode,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          ...receipt.items.map((item) => ListTile(
                dense: true,
                title: Text(item.name,
                    style: const TextStyle(fontSize: 13)),
                trailing: Text(
                  currency.format(item.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
