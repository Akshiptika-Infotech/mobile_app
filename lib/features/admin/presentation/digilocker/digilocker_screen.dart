import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton_loader.dart';
import 'package:mobile_app/features/admin/providers/digilocker_provider.dart';

class DigiLockerScreen extends ConsumerStatefulWidget {
  const DigiLockerScreen({super.key});

  @override
  ConsumerState<DigiLockerScreen> createState() => _DigiLockerScreenState();
}

class _DigiLockerScreenState extends ConsumerState<DigiLockerScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pins = ref.watch(digiLockerPinsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('DigiLocker PINs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by name or admission number',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: pins.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: AppSkeletonLoader.list(count: 8),
              ),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(digiLockerPinsProvider),
              ),
              data: (items) {
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = items.where((e) {
                  return q.isEmpty ||
                      e.studentName.toLowerCase().contains(q) ||
                      e.admissionNumber.toLowerCase().contains(q);
                }).toList();
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    message: 'No PINs found',
                    icon: Icons.lock_outline,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final pin = filtered[i];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        title: Text(pin.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Adm: ${pin.admissionNumber}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(pin.pin, style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined),
                              tooltip: 'Copy',
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: pin.pin));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('PIN copied')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
