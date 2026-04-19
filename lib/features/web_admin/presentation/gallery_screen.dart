import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/features/web_admin/data/web_admin_repository.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';
import 'package:mobile_app/features/web_admin/providers/web_admin_provider.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(galleryAlbumsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: albumsAsync.when(
        loading: () => const _AlbumsSkeleton(),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(galleryAlbumsProvider),
        ),
        data: (albums) => _AlbumsList(albums: albums),
      ),
    );
  }
}

class _AlbumsList extends ConsumerWidget {
  const _AlbumsList({required this.albums});
  final List<GalleryAlbum> albums;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (albums.isEmpty) {
      return Scaffold(
        body: const _EmptyState(
            message: 'No albums yet. Tap + to create one.'),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAlbumForm(context, ref),
          child: const Icon(Icons.add),
        ),
      );
    }
    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: albums.length,
        itemBuilder: (context, i) => _AlbumCard(
          album: albums[i],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(album: albums[i]),
            ),
          ),
          onEdit: () => _showAlbumForm(context, ref, album: albums[i]),
          onDelete: () => _confirmDelete(
            context,
            ref,
            label: albums[i].title,
            onConfirm: () async {
              await ref
                  .read(webAdminRepositoryProvider)
                  .deleteAlbum(albums[i].id);
              ref.invalidate(galleryAlbumsProvider);
              ref.invalidate(webDashboardProvider);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAlbumForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAlbumForm(
    BuildContext context,
    WidgetRef ref, {
    GalleryAlbum? album,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AlbumFormSheet(album: album, ref: ref),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.album,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final GalleryAlbum album;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  album.coverImage != null && album.coverImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: album.coverImage!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: cs.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _PlaceholderCover(),
                        )
                      : _PlaceholderCover(),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconBubble(
                          icon: Icons.edit_outlined,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 4),
                        _IconBubble(
                          icon: Icons.delete_outline,
                          onTap: onDelete,
                          color: cs.error,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${album.photoCount} photos',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                album.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.photo_library_outlined,
            size: 40, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color ?? Colors.white),
      ),
    );
  }
}

class _AlbumFormSheet extends ConsumerStatefulWidget {
  const _AlbumFormSheet({this.album, required this.ref});
  final GalleryAlbum? album;
  final WidgetRef ref;

  @override
  ConsumerState<_AlbumFormSheet> createState() => _AlbumFormSheetState();
}

class _AlbumFormSheetState extends ConsumerState<_AlbumFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.album?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.album?.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      };
      final repo = ref.read(webAdminRepositoryProvider);
      if (widget.album != null) {
        await repo.updateAlbum(widget.album!.id, data);
      } else {
        await repo.createAlbum(data);
      }
      ref.invalidate(galleryAlbumsProvider);
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
    final isEdit = widget.album != null;
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
                isEdit ? 'Edit Album' : 'New Album',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Album Title *',
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

// ── Album Detail ───────────────────────────────────────────────────────────────

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.album});
  final GalleryAlbum album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(albumPhotosProvider(album.id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(album.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit album',
            onPressed: () => _showAlbumEditForm(context, ref),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Delete album',
            onPressed: () => _deleteAlbum(context, ref),
          ),
        ],
      ),
      body: photosAsync.when(
        loading: () => const _PhotoGridSkeleton(),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(albumPhotosProvider(album.id)),
        ),
        data: (photos) => _PhotoGrid(
          photos: photos,
          albumId: album.id,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndUploadPhoto(context, ref),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Future<void> _showAlbumEditForm(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AlbumFormSheet(album: album, ref: ref),
    );
  }

  Future<void> _deleteAlbum(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Album'),
        content: Text(
            'Delete "${album.title}" and all its photos? This cannot be undone.'),
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
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(webAdminRepositoryProvider).deleteAlbum(album.id);
        ref.invalidate(galleryAlbumsProvider);
        ref.invalidate(webDashboardProvider);
        if (context.mounted) Navigator.of(context).pop();
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

  Future<void> _pickAndUploadPhoto(
      BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    try {
      await ref
          .read(webAdminRepositoryProvider)
          .uploadPhoto(album.id, File(picked.path));
      ref.invalidate(albumPhotosProvider(album.id));
      ref.invalidate(galleryAlbumsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid({required this.photos, required this.albumId});
  final List<GalleryPhoto> photos;
  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (photos.isEmpty) {
      return const _EmptyState(
          message: 'No photos yet. Tap the camera button to add photos.');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) => _PhotoTile(
        photo: photos[i],
        onDelete: () => _deletePhoto(context, ref, photos[i]),
      ),
    );
  }

  Future<void> _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    GalleryPhoto photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo? This cannot be undone.'),
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
        await ref
            .read(webAdminRepositoryProvider)
            .deletePhoto(albumId, photo.id);
        ref.invalidate(albumPhotosProvider(albumId));
        ref.invalidate(galleryAlbumsProvider);
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
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onDelete});
  final GalleryPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: photo.url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: cs.surfaceContainerHighest,
            ),
            errorWidget: (_, __, ___) => Container(
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_outlined,
                  color: cs.onSurfaceVariant),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoGridSkeleton extends StatelessWidget {
  const _PhotoGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).colorScheme.surfaceContainerHighest;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(color: shimmer),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

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

class _AlbumsSkeleton extends StatelessWidget {
  const _AlbumsSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).colorScheme.surfaceContainerHighest;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
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
