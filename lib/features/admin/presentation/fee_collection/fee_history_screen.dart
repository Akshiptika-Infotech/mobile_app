import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/domain/fee_model.dart';
import 'package:mobile_app/features/admin/providers/fee_provider.dart';

class FeeHistoryScreen extends ConsumerStatefulWidget {
  const FeeHistoryScreen({super.key});

  @override
  ConsumerState<FeeHistoryScreen> createState() => _FeeHistoryScreenState();
}

class _FeeHistoryScreenState extends ConsumerState<FeeHistoryScreen> {
  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feeHistoryProvider);
    final cs = Theme.of(context).colorScheme;

    final filtered = state.items.where((item) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isEmpty) return true;
      return item.studentName.toLowerCase().contains(q) ||
          item.admissionNumber.toLowerCase().contains(q) ||
          item.receiptNumber.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filter by date',
            onPressed: () => _showDateFilter(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, receipt or admission no.',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(feeHistoryProvider.notifier).load(),
        child: Builder(builder: (_) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: cs.error),
                  const SizedBox(height: 12),
                  Text(state.error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.read(feeHistoryProvider.notifier).load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color:
                          cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No records found.',
                      style:
                          TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _HistoryCard(
                  item: filtered[i],
                  fmt: _fmt,
                  onRevoke: () =>
                      _confirmRevoke(context, filtered[i]),
                ),
          );
        }),
      ),
    );
  }

  void _showDateFilter(BuildContext context) async {
    final state = ref.read(feeHistoryProvider);
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (state.dateFrom != null && state.dateTo != null)
          ? DateTimeRange(
              start: DateTime.parse(state.dateFrom!),
              end: DateTime.parse(state.dateTo!),
            )
          : null,
    );
    if (!mounted) return;
    if (range != null) {
      ref.read(feeHistoryProvider.notifier).setDateRange(
            range.start.toIso8601String().split('T').first,
            range.end.toIso8601String().split('T').first,
          );
    } else {
      ref.read(feeHistoryProvider.notifier).setDateRange(null, null);
    }
  }

  void _confirmRevoke(BuildContext context, FeeHistoryItem item) {
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Revoke receipt #${item.receiptNumber} for ${item.studentName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for revocation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(feeHistoryProvider.notifier).revoke(
                    item.id,
                    reasonCtrl.text.trim(),
                  );
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.fmt,
    required this.onRevoke,
  });

  final FeeHistoryItem item;
  final NumberFormat fmt;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color modeColor;
    IconData modeIcon;
    switch (item.paymentMode.toLowerCase()) {
      case 'online':
      case 'upi':
        modeColor = Colors.blue;
        modeIcon = Icons.phone_android_outlined;
        break;
      case 'cheque':
        modeColor = Colors.orange;
        modeIcon = Icons.account_balance_outlined;
        break;
      default:
        modeColor = Colors.green;
        modeIcon = Icons.payments_outlined;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    item.studentName.isNotEmpty
                        ? item.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                        [
                          if (item.className != null) item.className!,
                          '#${item.admissionNumber}',
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmt.format(item.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.receipt_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('#${item.receiptNumber}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(item.date,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(modeIcon, size: 12, color: modeColor),
                      const SizedBox(width: 4),
                      Text(item.paymentMode,
                          style: TextStyle(
                              color: modeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRevoke,
                icon: Icon(Icons.undo_outlined,
                    size: 16, color: cs.error),
                label: Text('Revoke',
                    style: TextStyle(color: cs.error, fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
