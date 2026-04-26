import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/utils/error_message.dart';
import 'package:mobile_app/features/admin/data/notification_repository.dart';

class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  String _role = 'all';
  bool _sending = false;

  static const _roles = ['all', 'student', 'parent', 'teacher', 'admin', 'staff'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _classCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await ref.read(notificationRepositoryProvider).sendNotification(
            _titleCtrl.text.trim(),
            _messageCtrl.text.trim(),
            _role,
            _classCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent')),
      );
      _titleCtrl.clear();
      _messageCtrl.clear();
      _classCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Send Notification'),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Target Role',
                  border: OutlineInputBorder(),
                ),
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _classCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Class (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Send Notification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
