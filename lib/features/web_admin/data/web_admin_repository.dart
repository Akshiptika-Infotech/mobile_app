import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/network/dio_client.dart';
import 'package:mobile_app/features/web_admin/domain/web_admin_models.dart';

class WebAdminRepository {
  const WebAdminRepository(this._dio);
  final Dio _dio;

  // ── Dashboard ──────────────────────────────────────────────────────────────

  Future<WebDashboardStats> fetchDashboard() async {
    final results = await Future.wait([
      _dio.get('/api/web-admin/news'),
      _dio.get('/api/web-admin/events'),
      _dio.get('/api/web-admin/gallery/albums'),
      _dio.get('/api/web-admin/pages'),
    ]);

    final news = _extractList(results[0].data)
        .map((e) => WebNewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
    final events = _extractList(results[1].data)
        .map((e) => WebEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    final albums = _extractList(results[2].data)
        .map((e) => GalleryAlbum.fromJson(e as Map<String, dynamic>))
        .toList();
    final pages = _extractList(results[3].data)
        .map((e) => WebPage.fromJson(e as Map<String, dynamic>))
        .toList();

    return WebDashboardStats.fromParts(
      news: news,
      events: events,
      albums: albums,
      pages: pages,
    );
  }

  // ── News ───────────────────────────────────────────────────────────────────

  Future<List<WebNewsArticle>> fetchNews() async {
    final res = await _dio.get('/api/web-admin/news');
    return _extractList(res.data)
        .map((e) => WebNewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createNews(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/news', data: data);
  }

  Future<void> updateNews(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/web-admin/news/$id', data: data);
  }

  Future<void> deleteNews(String id) async {
    await _dio.delete('/api/web-admin/news/$id');
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  Future<List<WebEvent>> fetchEvents() async {
    final res = await _dio.get('/api/web-admin/events');
    return _extractList(res.data)
        .map((e) => WebEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/events', data: data);
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/web-admin/events/$id', data: data);
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete('/api/web-admin/events/$id');
  }

  // ── Gallery Albums ─────────────────────────────────────────────────────────

  Future<List<GalleryAlbum>> fetchAlbums() async {
    final res = await _dio.get('/api/web-admin/gallery/albums');
    return _extractList(res.data)
        .map((e) => GalleryAlbum.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createAlbum(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/gallery/albums', data: data);
  }

  Future<void> updateAlbum(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/web-admin/gallery/albums/$id', data: data);
  }

  Future<void> deleteAlbum(String id) async {
    await _dio.delete('/api/web-admin/gallery/albums/$id');
  }

  // ── Gallery Photos ─────────────────────────────────────────────────────────

  Future<List<GalleryPhoto>> fetchAlbumPhotos(String albumId) async {
    final res = await _dio.get('/api/web-admin/gallery/albums/$albumId/photos');
    return _extractList(res.data)
        .map((e) => GalleryPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upload a photo to a gallery album.
  /// Step 1: POST the file to /api/admin/upload → get back the Cloudinary URL.
  /// Step 2: POST { imagePath: url } to the gallery photos endpoint.
  Future<void> uploadPhoto(String albumId, File photo) async {
    // Step 1: upload file to get Cloudinary URL
    final uploadForm = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        photo.path,
        filename: 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    final uploadRes = await _dio.post('/api/admin/upload', data: uploadForm);
    final uploadData = uploadRes.data as Map<String, dynamic>?;
    if (uploadData == null) throw Exception('Upload failed: empty response');
    final imagePath = (uploadData['url'] ?? uploadData['path'] ?? '').toString();

    // Step 2: register photo with album
    await _dio.post(
      '/api/web-admin/gallery/albums/$albumId/photos',
      data: {'imagePath': imagePath},
    );
  }

  Future<void> deletePhoto(String albumId, String photoId) async {
    await _dio.delete(
        '/api/web-admin/gallery/albums/$albumId/photos/$photoId');
  }

  // ── Testimonials ───────────────────────────────────────────────────────────

  Future<List<WebTestimonial>> fetchTestimonials() async {
    final res = await _dio.get('/api/web-admin/testimonials');
    return _extractList(res.data)
        .map((e) => WebTestimonial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTestimonial(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/testimonials', data: data);
  }

  Future<void> updateTestimonial(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/web-admin/testimonials/$id', data: data);
  }

  Future<void> deleteTestimonial(String id) async {
    await _dio.delete('/api/web-admin/testimonials/$id');
  }

  // ── Pages ──────────────────────────────────────────────────────────────────

  Future<List<WebPage>> fetchPages() async {
    final res = await _dio.get('/api/web-admin/pages');
    return _extractList(res.data)
        .map((e) => WebPage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPage(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/pages', data: data);
  }

  Future<void> updatePage(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/web-admin/pages/$id', data: data);
  }

  Future<void> deletePage(String id) async {
    await _dio.delete('/api/web-admin/pages/$id');
  }

  // ── Website Settings ───────────────────────────────────────────────────────

  Future<WebsiteSettings> fetchWebsiteSettings() async {
    final res = await _dio.get('/api/web-admin/website-settings');
    final data = res.data as Map<String, dynamic>;
    return WebsiteSettings.fromJson(data);
  }

  Future<void> patchWebsiteSettings(Map<String, dynamic> data) async {
    await _dio.patch('/api/web-admin/website-settings', data: data);
  }

  // ── Mandatory Disclosure ───────────────────────────────────────────────────

  Future<MandatoryGeneralInfo> fetchMandatoryGeneralInfo() async {
    final res = await _dio.get('/api/web-admin/mandatory/general-info');
    return MandatoryGeneralInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> saveMandatoryGeneralInfo(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/mandatory/general-info', data: data);
  }

  Future<MandatoryStaff> fetchMandatoryStaff() async {
    final res = await _dio.get('/api/web-admin/mandatory/staff');
    return MandatoryStaff.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> saveMandatoryStaff(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/mandatory/staff', data: data);
  }

  Future<MandatoryInfrastructure> fetchMandatoryInfrastructure() async {
    final res = await _dio.get('/api/web-admin/mandatory/infrastructure');
    return MandatoryInfrastructure.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> saveMandatoryInfrastructure(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/mandatory/infrastructure', data: data);
  }

  Future<List<MandatoryResult>> fetchMandatoryResults() async {
    final res = await _dio.get('/api/web-admin/mandatory/results');
    return _extractList(res.data)
        .map((e) => MandatoryResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createMandatoryResult(Map<String, dynamic> data) async {
    await _dio.post('/api/web-admin/mandatory/results', data: data);
  }

  Future<void> deleteMandatoryResult(String id) async {
    await _dio.delete('/api/web-admin/mandatory/results/$id');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      // News API returns { posts: [...] }, testimonials returns { testimonials: [...] }
      for (final key in [
        'posts',       // news
        'testimonials',
        'data',
        'news',
        'events',
        'albums',
        'photos',
        'pages',
        'items',
        'results',
      ]) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}

final webAdminRepositoryProvider = Provider<WebAdminRepository>((ref) {
  return WebAdminRepository(ref.watch(dioClientProvider));
});
