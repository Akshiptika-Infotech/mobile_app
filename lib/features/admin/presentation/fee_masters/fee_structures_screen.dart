import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/providers/fee_master_provider.dart';

class FeeStructuresScreen extends ConsumerWidget {
  const FeeStructuresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(feeStructuresProvider);
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Fee Structures'),
      ),
      body: list.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeletonLoader.list(count: 6),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(feeStructuresProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No fee structures found',
              icon: Icons.table_chart_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final s = items[i];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: ExpansionTile(
                  title: Text('${s.className} - ${s.section}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Year: ${s.academicYear}'),
                  children: s.feeItems
                      .map(
                        (item) => ListTile(
                          dense: true,
                          title: Text(item.feeTypeName),
                          subtitle: Text('Due: ${item.dueDate}'),
                          trailing: Text(money.format(item.amount)),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
