import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/security/domain/entry_exit_log_model.dart';
import 'package:mobile_app/features/security/domain/security_enums.dart';
import 'package:mobile_app/features/security/providers/security_providers.dart';

class EntryExitLogScreen extends ConsumerStatefulWidget {
  const EntryExitLogScreen({super.key});

  @override
  ConsumerState<EntryExitLogScreen> createState() => _EntryExitLogScreenState();
}

class _EntryExitLogScreenState extends ConsumerState<EntryExitLogScreen> {
  PersonType? _filter; // null = All

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(selectedDateProvider),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logsAsync = ref.watch(entryExitLogsProvider);
    final date = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Entry / Exit Log'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/security/entry-exit/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log'),
      ),
      body: Column(
        children: [
          Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM yyyy').format(date),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        fontSize: 14),
                  ),
                ),
                TextButton(onPressed: _pickDate, child: const Text('Change')),
              ],
            ),
          ),
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ...PersonType.values.map((p) => _FilterChip(
                        label: p.label,
                        selected: _filter == p,
                        onTap: () => setState(() => _filter = p),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(entryExitLogsProvider);
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child:
                        Text('Error: $e', style: TextStyle(color: cs.error)),
                  ),
                ]),
                data: (all) {
                  final logs = _filter == null
                      ? all
                      : all.where((l) => l.personType == _filter).toList();
                  if (logs.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                          child: Column(
                            children: [
                              Icon(Icons.swap_horiz_outlined,
                                  size: 64,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text('No logs for this filter',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: logs.length,
                    itemBuilder: (_, i) => _LogCard(log: logs[i]),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: cs.surfaceContainerHighest,
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});
  final EntryExitLog log;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEntry = log.logType == LogType.entry;
    final color = isEntry ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.personName ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${log.personType.label}'
                  '${log.personDetail != null ? ' · ${log.personDetail}' : ''}',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant),
                ),
                if ((log.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(log.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(DateFormat('h:mm a').format(log.loggedAt),
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(log.logType.label.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
