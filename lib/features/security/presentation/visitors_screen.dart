import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/core/printing/usb_printer_service.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/security_model.dart';
import 'package:mobile_app/features/security/presentation/visitor_pass_print.dart';
import 'package:mobile_app/features/security/providers/security_provider.dart';

class VisitorsScreen extends ConsumerWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final visitorsAsync = ref.watch(visitorsProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Visitors'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          _UsbStatusIcon(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(visitorsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterSheet(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Check In Visitor'),
      ),
      body: visitorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                    maxLines: 3),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(visitorsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (visitors) => visitors.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.35)),
                    const SizedBox(height: 16),
                    Text('No visitors today',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: visitors.length,
                itemBuilder: (_, i) => _VisitorCard(
                  visitor: visitors[i],
                  onCheckOut: () async {
                    await ref
                        .read(securityRepositoryProvider)
                        .checkOutVisitor(visitors[i].id);
                    ref.invalidate(visitorsProvider);
                    ref.invalidate(securityDashboardProvider);
                  },
                ),
              ),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RegisterSheet(onRegistered: () {
        ref.invalidate(visitorsProvider);
        ref.invalidate(securityDashboardProvider);
      }),
    );
  }
}

// ── Visitor card ──────────────────────────────────────────────────────────────

class _VisitorCard extends StatefulWidget {
  const _VisitorCard({required this.visitor, required this.onCheckOut});
  final Visitor visitor;
  final Future<void> Function() onCheckOut;

  @override
  State<_VisitorCard> createState() => _VisitorCardState();
}

class _VisitorCardState extends State<_VisitorCard> {
  bool _checkingOut = false;
  bool _printing = false;

  Color get _passColor {
    switch (widget.visitor.passStatus.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF10B981);
      case 'EXPIRED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _passLabel {
    switch (widget.visitor.passStatus.toUpperCase()) {
      case 'APPROVED':
        return 'Active';
      case 'USED':
        return 'Done';
      case 'EXPIRED':
        return 'Expired';
      default:
        return widget.visitor.passStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = widget.visitor;
    final isInside = v.isInside;
    final passColor = _passColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: passColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ──────────────────────────────────────────────────────
            Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: passColor.withValues(alpha: 0.12),
                  foregroundImage:
                      v.imagePath != null && v.imagePath!.isNotEmpty
                          ? CachedNetworkImageProvider(v.imagePath!)
                          : null,
                  child: Text(
                    v.name.isNotEmpty ? v.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: passColor,
                        fontSize: 20),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: passColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_passLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: passColor)),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  if (v.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(v.phone,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                  if (v.purpose.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(v.purpose,
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (v.personToMeet.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.person_rounded,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('Meet: ${v.personToMeet}',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  // Time row
                  Wrap(
                    spacing: 10,
                    children: [
                      _timeChip(
                          Icons.login_rounded, 'In ${v.inTime}', cs),
                      if (v.outTime != null)
                        _timeChip(Icons.logout_rounded,
                            'Out ${v.outTime!}', cs),
                      if (v.validUntil.isNotEmpty && isInside)
                        _timeChip(Icons.timer_outlined,
                            'Till ${v.validUntil}', cs,
                            color: const Color(0xFFDC2626)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _printing
                              ? null
                              : () async {
                                  setState(() => _printing = true);
                                  try {
                                    await printVisitorPass(context, v);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Print failed: ${e.toString()}'),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ));
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _printing = false);
                                    }
                                  }
                                },
                          icon: _printing
                              ? const SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.print_rounded, size: 15),
                          label: Text(_printing ? 'Printing...' : 'Print Pass'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            side: BorderSide(color: cs.primary),
                            padding:
                                const EdgeInsets.symmetric(vertical: 7),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (isInside) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _checkingOut
                                ? null
                                : () async {
                                    setState(() => _checkingOut = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final errorColor = Theme.of(context).colorScheme.error;
                                    try {
                                      await widget.onCheckOut();
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Check out failed: ${e.toString()}'),
                                          backgroundColor: errorColor,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) setState(() => _checkingOut = false);
                                    }
                                  },
                            icon: _checkingOut
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.logout_rounded,
                                    size: 15),
                            label: const Text('Check Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF6B7280),
                              side: const BorderSide(
                                  color: Color(0xFF6B7280)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 7),
                              textStyle:
                                  const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(IconData icon, String label, ColorScheme cs,
      {Color? color}) {
    final c = color ?? cs.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: c)),
      ],
    );
  }
}

// ── Register & Check In bottom sheet ─────────────────────────────────────────

class _RegisterSheet extends ConsumerStatefulWidget {
  const _RegisterSheet({required this.onRegistered});
  final VoidCallback onRegistered;

  @override
  ConsumerState<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends ConsumerState<_RegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _meetCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  int _validHours = 8;
  bool _submitting = false;
  File? _photo;
  bool _uploadingPhoto = false;

  static const _hourOptions = [1, 2, 4, 8, 24];
  static const _hourLabels = {
    1: '1 hour',
    2: '2 hours',
    4: '4 hours',
    8: '8 hours',
    24: 'Full day (24 hrs)',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _purposeCtrl.dispose();
    _meetCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xFile == null) return;
    setState(() {
      _photo = File(xFile.path);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      String? imagePath;
      if (_photo != null) {
        setState(() => _uploadingPhoto = true);
        imagePath = await ref
            .read(securityRepositoryProvider)
            .uploadVisitorPhoto(_photo!);
        setState(() => _uploadingPhoto = false);
      }
      await ref.read(securityRepositoryProvider).registerVisitor(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            purposeOfVisit: _purposeCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            personToMeet: _meetCtrl.text.trim(),
            vehicleNumber: _vehicleCtrl.text.trim(),
            imagePath: imagePath,
            validHours: _validHours,
          );
      widget.onRegistered();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Check In Visitor',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('Creates visitor pass & logs entry automatically',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 20),
              // ── Photo capture ──────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _submitting ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage:
                            _photo != null ? FileImage(_photo!) : null,
                        child: _photo == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded,
                                      size: 28, color: cs.onPrimaryContainer),
                                  const SizedBox(height: 2),
                                  Text('Photo',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: cs.onPrimaryContainer)),
                                ],
                              )
                            : null,
                      ),
                      if (_photo != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: cs.primary,
                            child: Icon(Icons.camera_alt_rounded,
                                size: 14, color: cs.onPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Full Name *', Icons.person_rounded,
                  required: true),
              const SizedBox(height: 10),
              _field(_phoneCtrl, 'Phone *', Icons.phone_rounded,
                  required: true, keyboard: TextInputType.phone),
              const SizedBox(height: 10),
              _field(_emailCtrl, 'Email', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  caps: TextCapitalization.none),
              const SizedBox(height: 10),
              _field(_purposeCtrl, 'Purpose of Visit *',
                  Icons.info_outline_rounded,
                  required: true),
              const SizedBox(height: 10),
              _field(_meetCtrl, 'Person to Meet', Icons.badge_rounded),
              const SizedBox(height: 10),
              _field(_vehicleCtrl, 'Vehicle Number',
                  Icons.directions_car_outlined,
                  caps: TextCapitalization.characters),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _validHours,
                decoration: InputDecoration(
                  labelText: 'Gate Pass Valid For',
                  prefixIcon: const Icon(Icons.timer_outlined),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                items: _hourOptions
                    .map((h) => DropdownMenuItem(
                          value: h,
                          child: Text(_hourLabels[h]!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _validHours = v ?? 8),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 8),
                            Text(_uploadingPhoto
                                ? 'Uploading photo...'
                                : 'Checking in...'),
                          ],
                        )
                      : const Text('Check In & Issue Pass'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }
}

// ── USB Printer status icon ───────────────────────────────────────────────────

class _UsbStatusIcon extends StatefulWidget {
  @override
  State<_UsbStatusIcon> createState() => _UsbStatusIconState();
}

class _UsbStatusIconState extends State<_UsbStatusIcon> {
  bool? _connected;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final c = await UsbPrinterService.instance.isPrinterConnected();
      if (mounted) setState(() => _connected = c);
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  void _showDiagnose() {
    // Show the dialog immediately with a loading state.
    // diagnose() runs INSIDE the dialog — never blocks the screen render.
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => _DiagnoseDialog(
        onClose: () {
          Navigator.of(dlgCtx).pop();
          _check(); // refresh USB icon after dialog closes
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _connected == true
        ? const Color(0xFF10B981)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return IconButton(
      icon: Icon(Icons.usb_rounded, color: color),
      tooltip: _connected == true ? 'Printer connected' : 'No printer detected',
      onPressed: _showDiagnose,
    );
  }
}

// ── Diagnose dialog (self-contained async load) ───────────────────────────────

class _DiagnoseDialog extends StatefulWidget {
  const _DiagnoseDialog({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_DiagnoseDialog> createState() => _DiagnoseDialogState();
}

class _DiagnoseDialogState extends State<_DiagnoseDialog> {
  String? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _info = null; });
    try {
      // 5-second timeout so a hung MethodChannel never stalls the UI.
      final result = await UsbPrinterService.instance
          .diagnose()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => 'Timed out — USB enumeration took too long.',
          );
      if (mounted) setState(() { _info = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _info = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('USB Printer Diagnose'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: SelectableText(
                  _info ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : _load,
          child: const Text('Refresh'),
        ),
        TextButton(
          onPressed: widget.onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}
