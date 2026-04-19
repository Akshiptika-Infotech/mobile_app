import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/web_admin/data/web_admin_repository.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';
import 'package:mobile_app/features/web_admin/providers/web_admin_provider.dart';

class PagesScreen extends ConsumerWidget {
  const PagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(webPagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Web Pages')),
      body: pagesAsync.when(
        loading: () => const _PagesSkeleton(),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(webPagesProvider),
        ),
        data: (pages) => _PagesList(pages: pages),
      ),
    );
  }
}

class _PagesList extends ConsumerWidget {
  const _PagesList({required this.pages});
  final List<WebPage> pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pages.isEmpty) {
      return Scaffold(
        body: const _EmptyState(
            message: 'No pages yet. Tap + to create one.'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showPageForm(context, ref),
          child: const Icon(Icons.add),
        ),
      );
    }
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pages.length,
        itemBuilder: (context, i) => _PageCard(
          page: pages[i],
          onEdit: () => _showPageForm(context, ref, page: pages[i]),
          onDelete: () => _confirmDelete(
            context,
            ref,
            label: pages[i].title,
            onConfirm: () async {
              await ref
                  .read(webAdminRepositoryProvider)
                  .deletePage(pages[i].id);
              ref.invalidate(webPagesProvider);
              ref.invalidate(webDashboardProvider);
            },
          ),
          onTogglePublish: (v) async {
            await ref.read(webAdminRepositoryProvider).updatePage(
                  pages[i].id,
                  {'isPublished': v},
                );
            ref.invalidate(webPagesProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPageForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showPageForm(
    BuildContext context,
    WidgetRef ref, {
    WebPage? page,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PageFormSheet(page: page, ref: ref),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.page,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  final WebPage page;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onTogglePublish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onEdit,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      page.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  _PublishedBadge(published: page.published),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.link_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '/${page.slug}',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
              if (page.metaDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  page.metaDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Switch(
                    value: page.published,
                    onChanged: onTogglePublish,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: cs.error),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageFormSheet extends ConsumerStatefulWidget {
  const _PageFormSheet({this.page, required this.ref});
  final WebPage? page;
  final WidgetRef ref;

  @override
  ConsumerState<_PageFormSheet> createState() => _PageFormSheetState();
}

class _PageFormSheetState extends ConsumerState<_PageFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _metaTitleCtrl;
  late final TextEditingController _metaDescCtrl;
  late bool _published;
  bool _loading = false;
  bool _slugManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.page?.title ?? '');
    _slugCtrl = TextEditingController(text: widget.page?.slug ?? '');
    _contentCtrl = TextEditingController(text: widget.page?.content ?? '');
    _metaTitleCtrl =
        TextEditingController(text: widget.page?.metaTitle ?? '');
    _metaDescCtrl =
        TextEditingController(text: widget.page?.metaDescription ?? '');
    _published = widget.page?.published ?? false;
    _slugManuallyEdited = widget.page != null;

    _titleCtrl.addListener(_onTitleChanged);
    _slugCtrl.addListener(() => _slugManuallyEdited = true);
  }

  void _onTitleChanged() {
    if (!_slugManuallyEdited) {
      final slug = _titleCtrl.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
      _slugCtrl.text = slug;
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    _contentCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'slug': _slugCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'metaTitle': _metaTitleCtrl.text.trim(),
        'metaDescription': _metaDescCtrl.text.trim(),
        'isPublished': _published,
      };
      final repo = ref.read(webAdminRepositoryProvider);
      if (widget.page != null) {
        await repo.updatePage(widget.page!.id, data);
      } else {
        await repo.createPage(data);
      }
      ref.invalidate(webPagesProvider);
      ref.invalidate(webDashboardProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.page != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit Page' : 'New Page',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Page Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slugCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slug *',
                  border: OutlineInputBorder(),
                  prefixText: '/',
                  hintText: 'auto-generated-from-title',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              const Text(
                'SEO',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _metaTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meta Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _metaDescCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meta Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Published'),
                value: _published,
                onChanged: (v) => setState(() => _published = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _PublishedBadge extends StatelessWidget {
  const _PublishedBadge({required this.published});
  final bool published;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: published
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        published ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: published ? const Color(0xFF10B981) : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref, {
  required String label,
  required Future<void> Function() onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete'),
      content: Text('Delete "$label"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    try {
      await onConfirm();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _PagesSkeleton extends StatelessWidget {
  const _PagesSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 110,
        decoration: BoxDecoration(
          color: shimmer,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
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
