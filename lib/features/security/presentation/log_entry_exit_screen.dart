import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/entry_exit_log_model.dart';
import 'package:mobile_app/features/security/domain/security_enums.dart';
import 'package:mobile_app/features/security/domain/security_visitor_model.dart';
import 'package:mobile_app/features/security/providers/security_providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Form to record an entry/exit. For VISITOR we offer a picker scoped to
/// today's visitors (already fetched by `visitorsProvider`); for other
/// person types we accept free-text notes plus an optional gate-pass scan
/// that will auto-mark the pass USED server-side.
class LogEntryExitScreen extends ConsumerStatefulWidget {
  const LogEntryExitScreen({super.key, this.scanFirst = false});

  /// When true the QR scanner opens immediately (deep-link from the
  /// dashboard's "Scan gate pass" quick action).
  final bool scanFirst;

  @override
  ConsumerState<LogEntryExitScreen> createState() => _LogEntryExitScreenState();
}

class _LogEntryExitScreenState extends ConsumerState<LogEntryExitScreen> {
  LogType _logType = LogType.entry;
  PersonType _personType = PersonType.visitor;
  SecurityVisitor? _selectedVisitor;
  String? _gatePassId;
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.scanFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const _QrScanRoute(),
        fullscreenDialog: true,
      ),
    );
    if (raw == null || raw.isEmpty) return;
    setState(() {
      _gatePassId = raw;
      // The backend marks the pass USED + writes an EXIT log when gatePassId
      // is included, so default to EXIT for scanned passes.
      _logType = LogType.exit;
    });
  }

  Future<void> _submit() async {
    if (_personType == PersonType.visitor && _selectedVisitor == null && _gatePassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pick a visitor or scan a gate pass.')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final go = GoRouter.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(securityRepositoryProvider).logEntryExit(
            EntryExitPayload(
              logType: _logType,
              personType: _personType,
              visitorId: _personType == PersonType.visitor
                  ? _selectedVisitor?.id
                  : null,
              gatePassId: _gatePassId,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
          );
      ref.invalidate(entryExitLogsProvider);
      ref.invalidate(visitorsProvider);
      ref.invalidate(activeGatePassesProvider);
      messenger.showSnackBar(const SnackBar(
          content: Text('Logged.')));
      go.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visitorsAsync = ref.watch(visitorsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Log Entry / Exit'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan gate pass',
            onPressed: _scan,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Log type ──
          const _Label('Type'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _Segmented(
                  label: 'Entry',
                  icon: Icons.login_rounded,
                  selected: _logType == LogType.entry,
                  color: const Color(0xFF10B981),
                  onTap: () => setState(() => _logType = LogType.entry),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Segmented(
                  label: 'Exit',
                  icon: Icons.logout_rounded,
                  selected: _logType == LogType.exit,
                  color: const Color(0xFFEF4444),
                  onTap: () => setState(() => _logType = LogType.exit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Person type ──
          const _Label('Person'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PersonType.values
                .map((p) => ChoiceChip(
                      label: Text(p.label),
                      selected: _personType == p,
                      onSelected: (_) {
                        setState(() {
                          _personType = p;
                          if (p != PersonType.visitor) _selectedVisitor = null;
                        });
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),

          if (_personType == PersonType.visitor) ...[
            const _Label('Today\'s visitors'),
            const SizedBox(height: 6),
            visitorsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('Failed to load visitors: $e',
                      style: TextStyle(color: cs.error)),
              data: (visitors) => DropdownButtonFormField<String?>(
                initialValue: _selectedVisitor?.id,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_rounded),
                  labelText: 'Pick a visitor',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('— None —')),
                  ...visitors.map((v) => DropdownMenuItem<String?>(
                        value: v.id,
                        child: Text('${v.fullName} · ${v.phone}',
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (id) {
                  setState(() {
                    _selectedVisitor = id == null
                        ? null
                        : visitors.firstWhere((v) => v.id == id);
                  });
                },
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (_gatePassId != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Gate pass scanned: $_gatePassId',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _gatePassId = null),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.note_alt_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Log it'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color : cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : cs.onSurface,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrScanRoute extends StatefulWidget {
  const _QrScanRoute();
  @override
  State<_QrScanRoute> createState() => _QrScanRouteState();
}

class _QrScanRouteState extends State<_QrScanRoute> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan gate pass'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}
