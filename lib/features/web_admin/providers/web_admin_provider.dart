import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/web_admin/data/web_admin_repository.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';

final webDashboardProvider = FutureProvider<WebDashboardStats>((ref) {
  return ref.watch(webAdminRepositoryProvider).fetchDashboard();
});

final webNewsProvider = FutureProvider.autoDispose<List<WebNewsArticle>>((ref) {
  return ref.watch(webAdminRepositoryProvider).fetchNews();
});

final webEventsProvider = FutureProvider.autoDispose<List<WebEvent>>((ref) {
  return ref.watch(webAdminRepositoryProvider).fetchEvents();
});

final galleryAlbumsProvider =
    FutureProvider.autoDispose<List<GalleryAlbum>>((ref) {
  return ref.watch(webAdminRepositoryProvider).fetchAlbums();
});

final albumPhotosProvider =
    FutureProvider.autoDispose.family<List<GalleryPhoto>, String>((ref, albumId) {
  return ref.watch(webAdminRepositoryProvider).fetchAlbumPhotos(albumId);
});

final webTestimonialsProvider =
    FutureProvider.autoDispose<List<WebTestimonial>>((ref) {
  return ref.watch(webAdminRepositoryProvider).fetchTestimonials();
});

final webPagesProvider = FutureProvider.autoDispose<List<WebPage>>((ref) {
  return ref.watch(webAdminRepositoryProvider).fetchPages();
});

final websiteSettingsProvider =
    FutureProvider.autoDispose<WebsiteSettings>((ref) {
  return ref.watch(webAdminRepositoryProvider).fetchWebsiteSettings();
});
