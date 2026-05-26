import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/features/security/data/security_repository.dart';
import 'package:mobile_app/features/security/domain/security_visitor_model.dart';
import 'package:mobile_app/features/security/providers/security_providers.dart';

class RegisterVisitorScreen extends ConsumerStatefulWidget {
  const RegisterVisitorScreen({super.key});

  @override
  ConsumerState<RegisterVisitorScreen> createState() =>
      _RegisterVisitorScreenState();
}

class _RegisterVisitorScreenState
    extends ConsumerState<RegisterVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _purpose = TextEditingController();
  final _meeting = TextEditingController();
  final _vehicle = TextEditingController();
  int _validHours = 8;
  String? _photoUrl;
  bool _uploadingPhoto = false;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _purpose.dispose();
    _meeting.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 75, maxWidth: 1024);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref
          .read(securityRepositoryProvider)
          .uploadVisitorPhoto(picked.path);
      setState(() => _photoUrl = url);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final go = GoRouter.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(securityRepositoryProvider).registerVisitor(
            RegisterVisitorPayload(
              fullName: _name.text.trim(),
              phone: _phone.text.trim(),
              email: _email.text.trim().isEmpty ? null : _email.text.trim(),
              purposeOfVisit: _purpose.text.trim(),
              personToMeet: _meeting.text.trim(),
              vehicleNumber:
                  _vehicle.text.trim().isEmpty ? null : _vehicle.text.trim(),
              imagePath: _photoUrl,
              validHours: _validHours,
            ),
          );
      ref.invalidate(visitorsProvider);
      ref.invalidate(entryExitLogsProvider);
      ref.invalidate(activeGatePassesProvider);
      messenger.showSnackBar(const SnackBar(
          content: Text('Visitor registered. Gate pass approved.')));
      go.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Register failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Register Visitor'), centerTitle: false),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _PhotoPicker(
              photoUrl: _photoUrl,
              isUploading: _uploadingPhoto,
              onTap: _pickPhoto,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().length < 7) ? 'Enter a valid phone' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purpose,
              decoration: const InputDecoration(
                labelText: 'Purpose of visit *',
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _meeting,
              decoration: const InputDecoration(
                labelText: 'Person to meet *',
                prefixIcon: Icon(Icons.person_pin_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vehicle,
              decoration: const InputDecoration(
                labelText: 'Vehicle number (optional)',
                prefixIcon: Icon(Icons.directions_car_rounded),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _validHours,
              decoration: const InputDecoration(
                labelText: 'Gate pass valid for',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              items: const [1, 2, 4, 8, 12, 24]
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text('$h hour${h == 1 ? '' : 's'}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _validHours = v);
              },
            ),
            const SizedBox(height: 24),
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
              label: const Text('Register & Approve Pass'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoUrl,
    required this.isUploading,
    required this.onTap,
  });
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: GestureDetector(
        onTap: isUploading ? null : onTap,
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            image: (photoUrl != null && photoUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(photoUrl!),
                    fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: isUploading
              ? const CircularProgressIndicator()
              : (photoUrl == null || photoUrl!.isEmpty)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: cs.onPrimaryContainer, size: 28),
                        const SizedBox(height: 4),
                        Text('Photo',
                            style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      width: 110,
                      height: 110,
                      alignment: Alignment.bottomCenter,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Change',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
        ),
      ),
    );
  }
}
