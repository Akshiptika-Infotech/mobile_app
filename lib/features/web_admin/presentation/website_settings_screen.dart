import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/web_admin/data/web_admin_repository.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';
import 'package:mobile_app/features/web_admin/providers/web_admin_provider.dart';

class WebsiteSettingsScreen extends ConsumerWidget {
  const WebsiteSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(websiteSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Website Settings')),
      body: settingsAsync.when(
        loading: () => const _SettingsSkeleton(),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(websiteSettingsProvider),
        ),
        data: (settings) => _SettingsForm(settings: settings),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});
  final WebsiteSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Branding
  late final TextEditingController _schoolNameCtrl;
  late final TextEditingController _initialsCtrl;
  late final TextEditingController _taglineCtrl;

  // Contact
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  // Social
  late final TextEditingController _facebookCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _youtubeCtrl;
  late final TextEditingController _twitterCtrl;

  // Stats
  late final TextEditingController _studentCountCtrl;
  late final TextEditingController _facultyCountCtrl;
  late final TextEditingController _batchCountCtrl;
  late final TextEditingController _boardCtrl;

  // Map
  late final TextEditingController _mapEmbedCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _schoolNameCtrl = TextEditingController(text: s.schoolName);
    _initialsCtrl = TextEditingController(text: s.schoolInitials);
    _taglineCtrl = TextEditingController(text: s.tagline);
    _emailCtrl = TextEditingController(text: s.contactEmail);
    _phoneCtrl = TextEditingController(text: s.contactPhone);
    _addressCtrl = TextEditingController(text: s.address);
    _facebookCtrl = TextEditingController(text: s.facebook);
    _instagramCtrl = TextEditingController(text: s.instagram);
    _youtubeCtrl = TextEditingController(text: s.youtube);
    _twitterCtrl = TextEditingController(text: s.twitter);
    _studentCountCtrl = TextEditingController(text: s.studentCount);
    _facultyCountCtrl = TextEditingController(text: s.facultyCount);
    _batchCountCtrl = TextEditingController(text: s.batchCount);
    _boardCtrl = TextEditingController(text: s.board);
    _mapEmbedCtrl = TextEditingController(text: s.mapEmbedUrl);
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _initialsCtrl.dispose();
    _taglineCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _youtubeCtrl.dispose();
    _twitterCtrl.dispose();
    _studentCountCtrl.dispose();
    _facultyCountCtrl.dispose();
    _batchCountCtrl.dispose();
    _boardCtrl.dispose();
    _mapEmbedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'schoolName': _schoolNameCtrl.text.trim(),
        'schoolInitials': _initialsCtrl.text.trim(),
        'tagline': _taglineCtrl.text.trim(),
        'contactEmail': _emailCtrl.text.trim(),
        'contactPhone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'facebook': _facebookCtrl.text.trim(),
        'instagram': _instagramCtrl.text.trim(),
        'youtube': _youtubeCtrl.text.trim(),
        'twitter': _twitterCtrl.text.trim(),
        'studentCount': _studentCountCtrl.text.trim(),
        'facultyCount': _facultyCountCtrl.text.trim(),
        'batchCount': _batchCountCtrl.text.trim(),
        'board': _boardCtrl.text.trim(),
        'mapEmbedUrl': _mapEmbedCtrl.text.trim(),
      };
      await ref.read(webAdminRepositoryProvider).patchWebsiteSettings(data);
      ref.invalidate(websiteSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Branding ──────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.school_outlined,
            label: 'Branding',
          ),
          _Field(
            controller: _schoolNameCtrl,
            label: 'School Name *',
            validator: _required,
          ),
          _Field(
            controller: _initialsCtrl,
            label: 'School Initials',
            hint: 'e.g. JMUKHISICS',
          ),
          _Field(
            controller: _taglineCtrl,
            label: 'Tagline',
            hint: 'e.g. Excellence in Education',
          ),
          const SizedBox(height: 8),

          // ── Contact ───────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.contact_phone_outlined,
            label: 'Contact',
          ),
          _Field(
            controller: _emailCtrl,
            label: 'Contact Email',
            keyboardType: TextInputType.emailAddress,
          ),
          _Field(
            controller: _phoneCtrl,
            label: 'Contact Phone',
            keyboardType: TextInputType.phone,
          ),
          _Field(
            controller: _addressCtrl,
            label: 'Address',
            maxLines: 3,
          ),
          const SizedBox(height: 8),

          // ── Social Media ──────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.share_outlined,
            label: 'Social Media',
          ),
          _Field(
            controller: _facebookCtrl,
            label: 'Facebook URL',
            prefixIcon: Icons.facebook_outlined,
          ),
          _Field(
            controller: _instagramCtrl,
            label: 'Instagram URL',
            prefixIcon: Icons.camera_alt_outlined,
          ),
          _Field(
            controller: _youtubeCtrl,
            label: 'YouTube URL',
            prefixIcon: Icons.play_circle_outline,
          ),
          _Field(
            controller: _twitterCtrl,
            label: 'Twitter / X URL',
            prefixIcon: Icons.alternate_email_outlined,
          ),
          const SizedBox(height: 8),

          // ── Statistics ────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.bar_chart_outlined,
            label: 'Statistics',
          ),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _studentCountCtrl,
                  label: 'Students',
                  hint: 'e.g. 1200',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _facultyCountCtrl,
                  label: 'Faculty',
                  hint: 'e.g. 80',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _batchCountCtrl,
                  label: 'Batches / Years',
                  hint: 'e.g. 25',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  controller: _boardCtrl,
                  label: 'Board',
                  hint: 'e.g. CBSE',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Map ───────────────────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.map_outlined,
            label: 'Map',
          ),
          _Field(
            controller: _mapEmbedCtrl,
            label: 'Google Maps Embed URL',
            hint: 'https://maps.google.com/...',
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_loading ? 'Saving...' : 'Save Settings'),
          ),
        ],
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: cs.outlineVariant)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}

// ── Loading / Error states ─────────────────────────────────────────────────────

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 56,
        decoration: BoxDecoration(
          color: shimmer,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
