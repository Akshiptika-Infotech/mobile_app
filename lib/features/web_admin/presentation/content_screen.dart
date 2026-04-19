import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/web_admin/data/web_admin_repository.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';
import 'package:mobile_app/features/web_admin/providers/web_admin_provider.dart';

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'News'),
            Tab(text: 'Events'),
            Tab(text: 'Testimonials'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NewsTab(),
          _EventsTab(),
          _TestimonialsTab(),
        ],
      ),
    );
  }
}

// ── News Tab ──────────────────────────────────────────────────────────────────

class _NewsTab extends ConsumerWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(webNewsProvider);
    return newsAsync.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(webNewsProvider),
      ),
      data: (news) => _NewsList(items: news),
    );
  }
}

class _NewsList extends ConsumerWidget {
  const _NewsList({required this.items});
  final List<WebNewsArticle> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _EmptyState(
          message: 'No news articles yet. Tap + to create one.');
    }
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) => _NewsCard(
          article: items[i],
          onEdit: () => _showNewsForm(context, ref, article: items[i]),
          onDelete: () => _confirmDelete(
            context,
            ref,
            label: items[i].title,
            onConfirm: () async {
              await ref
                  .read(webAdminRepositoryProvider)
                  .deleteNews(items[i].id);
              ref.invalidate(webNewsProvider);
              ref.invalidate(webDashboardProvider);
            },
          ),
          onTogglePublish: (v) async {
            await ref.read(webAdminRepositoryProvider).updateNews(
                  items[i].id,
                  {'isPublished': v},
                );
            ref.invalidate(webNewsProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'news_fab',
        onPressed: () => _showNewsForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showNewsForm(
    BuildContext context,
    WidgetRef ref, {
    WebNewsArticle? article,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NewsFormSheet(article: article, ref: ref),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.article,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  final WebNewsArticle article;
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
                      article.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  _PublishedBadge(published: article.published),
                ],
              ),
              if (article.excerpt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  article.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(article.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Switch(
                    value: article.published,
                    onChanged: onTogglePublish,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
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

class _NewsFormSheet extends ConsumerStatefulWidget {
  const _NewsFormSheet({this.article, required this.ref});
  final WebNewsArticle? article;
  final WidgetRef ref;

  @override
  ConsumerState<_NewsFormSheet> createState() => _NewsFormSheetState();
}

class _NewsFormSheetState extends ConsumerState<_NewsFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _excerptCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _imageCtrl;
  late bool _published;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.article?.title ?? '');
    _excerptCtrl =
        TextEditingController(text: widget.article?.excerpt ?? '');
    _contentCtrl =
        TextEditingController(text: widget.article?.content ?? '');
    _imageCtrl =
        TextEditingController(text: widget.article?.featuredImage ?? '');
    _published = widget.article?.published ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _excerptCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'excerpt': _excerptCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'isPublished': _published,
        if (_imageCtrl.text.trim().isNotEmpty)
          'featuredImage': _imageCtrl.text.trim(),
      };
      final repo = ref.read(webAdminRepositoryProvider);
      if (widget.article != null) {
        await repo.updateNews(widget.article!.id, data);
      } else {
        await repo.createNews(data);
      }
      ref.invalidate(webNewsProvider);
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
    final isEdit = widget.article != null;
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
                isEdit ? 'Edit Article' : 'New Article',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _excerptCtrl,
                decoration: const InputDecoration(
                  labelText: 'Excerpt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Featured Image URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
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

// ── Events Tab ────────────────────────────────────────────────────────────────

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(webEventsProvider);
    return eventsAsync.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(webEventsProvider),
      ),
      data: (events) => _EventsList(items: events),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList({required this.items});
  final List<WebEvent> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _EmptyState(message: 'No events yet. Tap + to create one.');
    }
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) => _EventCard(
          event: items[i],
          onEdit: () => _showEventForm(context, ref, event: items[i]),
          onDelete: () => _confirmDelete(
            context,
            ref,
            label: items[i].title,
            onConfirm: () async {
              await ref
                  .read(webAdminRepositoryProvider)
                  .deleteEvent(items[i].id);
              ref.invalidate(webEventsProvider);
              ref.invalidate(webDashboardProvider);
            },
          ),
          onTogglePublish: (v) async {
            await ref.read(webAdminRepositoryProvider).updateEvent(
                  items[i].id,
                  {'isPublished': v},
                );
            ref.invalidate(webEventsProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'events_fab',
        onPressed: () => _showEventForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEventForm(
    BuildContext context,
    WidgetRef ref, {
    WebEvent? event,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EventFormSheet(event: event, ref: ref),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  final WebEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onTogglePublish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM yyyy');
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
                      event.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  _PublishedBadge(published: event.published),
                ],
              ),
              const SizedBox(height: 6),
              if (event.location.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(event.location,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.date_range_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${fmt.format(event.startDate)} – ${fmt.format(event.endDate)}',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Switch(
                    value: event.published,
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

class _EventFormSheet extends ConsumerStatefulWidget {
  const _EventFormSheet({this.event, required this.ref});
  final WebEvent? event;
  final WidgetRef ref;

  @override
  ConsumerState<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<_EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _imageCtrl;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _published;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.event?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.event?.description ?? '');
    _locationCtrl =
        TextEditingController(text: widget.event?.location ?? '');
    _imageCtrl =
        TextEditingController(text: widget.event?.featuredImage ?? '');
    _startDate = widget.event?.startDate ?? DateTime.now();
    _endDate = widget.event?.endDate ??
        DateTime.now().add(const Duration(days: 1));
    _published = widget.event?.published ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'isPublished': _published,
        if (_imageCtrl.text.trim().isNotEmpty)
          'featuredImage': _imageCtrl.text.trim(),
      };
      final repo = ref.read(webAdminRepositoryProvider);
      if (widget.event != null) {
        await repo.updateEvent(widget.event!.id, data);
      } else {
        await repo.createEvent(data);
      }
      ref.invalidate(webEventsProvider);
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
    final fmt = DateFormat('d MMM yyyy');
    final isEdit = widget.event != null;
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
                isEdit ? 'Edit Event' : 'New Event',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Start: ${fmt.format(_startDate)}'),
                      onPressed: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('End: ${fmt.format(_endDate)}'),
                      onPressed: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Featured Image URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
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

// ── Testimonials Tab ──────────────────────────────────────────────────────────

class _TestimonialsTab extends ConsumerWidget {
  const _TestimonialsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonialsAsync = ref.watch(webTestimonialsProvider);
    return testimonialsAsync.when(
      loading: () => const _ListSkeleton(),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(webTestimonialsProvider),
      ),
      data: (items) => _TestimonialsList(items: items),
    );
  }
}

class _TestimonialsList extends ConsumerWidget {
  const _TestimonialsList({required this.items});
  final List<WebTestimonial> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _EmptyState(
          message: 'No testimonials yet. Tap + to create one.');
    }
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) => _TestimonialCard(
          item: items[i],
          onEdit: () => _showForm(context, ref, item: items[i]),
          onDelete: () => _confirmDelete(
            context,
            ref,
            label: items[i].personName,
            onConfirm: () async {
              await ref
                  .read(webAdminRepositoryProvider)
                  .deleteTestimonial(items[i].id);
              ref.invalidate(webTestimonialsProvider);
            },
          ),
          onTogglePublish: (v) async {
            await ref.read(webAdminRepositoryProvider).updateTestimonial(
                  items[i].id,
                  {'isPublished': v},
                );
            ref.invalidate(webTestimonialsProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'testimonials_fab',
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    WebTestimonial? item,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TestimonialFormSheet(item: item, ref: ref),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  final WebTestimonial item;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.personName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          item.personRole,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _PublishedBadge(published: item.published),
                ],
              ),
              if (item.caption.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.videoUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: cs.primary),
                    ),
                  ),
                  Text(
                    'Order: ${item.displayOrder}',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Switch(
                    value: item.published,
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

class _TestimonialFormSheet extends ConsumerStatefulWidget {
  const _TestimonialFormSheet({this.item, required this.ref});
  final WebTestimonial? item;
  final WidgetRef ref;

  @override
  ConsumerState<_TestimonialFormSheet> createState() =>
      _TestimonialFormSheetState();
}

class _TestimonialFormSheetState
    extends ConsumerState<_TestimonialFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _thumbnailCtrl;
  late final TextEditingController _captionCtrl;
  late final TextEditingController _orderCtrl;
  late bool _published;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.item?.personName ?? '');
    _roleCtrl =
        TextEditingController(text: widget.item?.personRole ?? '');
    _videoUrlCtrl =
        TextEditingController(text: widget.item?.videoUrl ?? '');
    _thumbnailCtrl =
        TextEditingController(text: widget.item?.thumbnailUrl ?? '');
    _captionCtrl =
        TextEditingController(text: widget.item?.caption ?? '');
    _orderCtrl = TextEditingController(
        text: (widget.item?.displayOrder ?? 0).toString());
    _published = widget.item?.published ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _videoUrlCtrl.dispose();
    _thumbnailCtrl.dispose();
    _captionCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'personName': _nameCtrl.text.trim(),
        'role': _roleCtrl.text.trim(),
        'videoUrl': _videoUrlCtrl.text.trim(),
        'caption': _captionCtrl.text.trim(),
        'isPublished': _published,
        'displayOrder':
            int.tryParse(_orderCtrl.text.trim()) ?? 0,
        if (_thumbnailCtrl.text.trim().isNotEmpty)
          'thumbnailUrl': _thumbnailCtrl.text.trim(),
      };
      final repo = ref.read(webAdminRepositoryProvider);
      if (widget.item != null) {
        await repo.updateTestimonial(widget.item!.id, data);
      } else {
        await repo.createTestimonial(data);
      }
      ref.invalidate(webTestimonialsProvider);
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
    final isEdit = widget.item != null;
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
                isEdit ? 'Edit Testimonial' : 'New Testimonial',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Person Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Role (e.g. Parent, Student)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _videoUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Video URL *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_library_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thumbnailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _captionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Order',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
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
            Icon(Icons.inbox_outlined, size: 64, color: cs.onSurfaceVariant),
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
