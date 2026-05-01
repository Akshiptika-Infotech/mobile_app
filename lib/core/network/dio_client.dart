import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/app_config.dart';
import 'package:uuid/uuid.dart';

/// Provides a configured [Dio] instance scoped to the current [AppConfig].
final dioClientProvider = Provider<Dio>((ref) {
  throw UnimplementedError(
    'dioClientProvider must be overridden with the flavor AppConfig.',
  );
});

/// Builds a fully configured [Dio] instance.
///
/// [cookieDir] — when supplied, a [PersistCookieJar] is used so cookies
/// survive app restarts. Omit (or pass null) to use an in-memory jar.
///
/// [onUnauthorized] — called on any 401 response. Wire this to
/// `authProvider.notifier.logout()` in the app's [ProviderContainer] setup
/// to automatically redirect users to the login screen.
Dio buildDioClient(
  AppConfig config, {
  String? cookieDir,
  Future<void> Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // Cookie jar — persistent when cookieDir is provided, in-memory otherwise.
  final CookieJar cookieJar = cookieDir != null
      ? PersistCookieJar(storage: FileStorage('$cookieDir/cookies/'))
      : CookieJar();
  dio.interceptors.add(CookieManager(cookieJar));

  // Debug-only request/response logger.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        // ignore: avoid_print
        logPrint: (o) => print('[DioClient] $o'),
      ),
    );
  }

  // 401 interceptor — clears session and triggers logout.
  if (onUnauthorized != null) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          if (response.statusCode == 401) {
            onUnauthorized();
          }
          handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          if (e.response?.statusCode == 401) {
            onUnauthorized();
          }
          handler.next(e);
        },
      ),
    );
  }

  // Request tracing — every request gets a unique X-Request-Id header
  // so backend logs can trace a single request across retries.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Request-Id'] = const Uuid().v4();
        handler.next(options);
      },
    ),
  );

  // Retry interceptor — retries up to 2 times on network timeouts or 5xx.
  dio.interceptors.add(_RetryInterceptor(dio, maxRetries: 2));

  return dio;
}

/// Retries failed requests on transient errors (timeouts and 5xx responses).
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio, {required this.maxRetries});

  final Dio _dio;
  final int maxRetries;

  static const _retryCountKey = '_retryCount';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final extra = Map<String, dynamic>.from(err.requestOptions.extra);
    final retryCount = (extra[_retryCountKey] as int?) ?? 0;

    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    extra[_retryCountKey] = retryCount + 1;
    final options = err.requestOptions.copyWith(extra: extra);

    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[DioClient] Retrying (${retryCount + 1}/$maxRetries): '
        '${options.method} ${options.path}',
      );
    }

    await Future<void>.delayed(const Duration(seconds: 1));

    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status >= 500 && status < 600;
      default:
        return false;
    }
  }
}
