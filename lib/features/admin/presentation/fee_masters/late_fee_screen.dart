import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/features/admin/data/fee_master_repository.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/providers/fee_master_provider.dart';

class LateFeeScreen extends ConsumerStatefulWidget {
  const LateFeeScreen({super.key});

  @override
  ConsumerState<LateFeeScreen> createState() => _LateFeeScreenState();
}

class _LateFeeScreenState extends ConsumerState<LateFeeScreen> {
  final _graceCtrl = TextEditingController();
  final _perDayCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _graceCtrl.dispose();
    _perDayCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(feeMasterRepositoryProvider).updateLateFeeConfig({
        'graceDays': int.tryParse(_graceCtrl.text.trim()) ?? 0,
        'finePerDay': double.tryParse(_perDayCtrl.text.trim()) ?? 0,
        'maxFine': double.tryParse(_maxCtrl.text.trim()) ?? 0,
      });
      ref.invalidate(lateFeeConfigProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Late fee config saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(lateFeeConfigProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Late Fee Config'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: config.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(lateFeeConfigProvider),
        ),
        data: (item) {
          if (!_loaded) {
            _graceCtrl.text = item.graceDays.toString();
            _perDayCtrl.text = item.finePerDay.toStringAsFixed(0);
            _maxCtrl.text = item.maxFine.toStringAsFixed(0);
            _loaded = true;
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _graceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Grace Days',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _perDayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fine Per Day',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Fine',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
