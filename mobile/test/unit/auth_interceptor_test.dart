import 'dart:convert';
import 'dart:typed_data';

import 'package:aesthetic_coach/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake transport: per-path queue of HTTP statuses, so a test can say
/// "first call to /protected returns 401, the retry returns 200"
/// without a real network round trip. Records every [RequestOptions]
/// that reaches it, so tests can inspect headers (e.g. `Authorization`)
/// and count exactly how many times a path was actually hit.
class _RecordingAdapter implements HttpClientAdapter {
  final Map<String, List<int>> statusQueue = {};
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final queue = statusQueue[options.path];
    final status = (queue != null && queue.isNotEmpty)
        ? queue.removeAt(0)
        : 200;
    final body = status == 401
        ? {
            'error': {'code': 'unauthenticated', 'message': 'x'},
          }
        : {'data': 'ok'};

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthInterceptor', () {
    late _RecordingAdapter adapter;
    late Dio dio;
    late String? currentToken;
    late int refreshCalls;
    late bool refreshSucceeds;
    late int sessionRevokedCalls;

    setUp(() {
      adapter = _RecordingAdapter();
      currentToken = 'initial-token';
      refreshCalls = 0;
      refreshSucceeds = true;
      sessionRevokedCalls = 0;

      dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          getAccessToken: () async => currentToken,
          refreshTokens: () async {
            refreshCalls++;
            // Deliberate small delay so concurrent-401 tests genuinely
            // overlap in-flight rather than accidentally resolving
            // sequentially.
            await Future<void>.delayed(const Duration(milliseconds: 5));
            if (refreshSucceeds) {
              currentToken = 'refreshed-token';
              return true;
            }
            return false;
          },
          onSessionRevoked: () => sessionRevokedCalls++,
        ),
      );
    });

    test(
      'attaches the Authorization header when a token is available',
      () async {
        await dio.get<void>('ping');
        expect(
          adapter.requests.single.headers['Authorization'],
          'Bearer initial-token',
        );
      },
    );

    test('sends no Authorization header when no token is available (public request)', () async {
      currentToken = null;
      await dio.get<void>('ping');
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('a successful (non-401) request passes through without attempting a refresh', () async {
      final response = await dio.get<void>('ping');
      expect(response.statusCode, 200);
      expect(refreshCalls, 0);
    });

    test('401 triggers a refresh, retries the original request exactly once, and the retry carries the new token', () async {
      adapter.statusQueue['protected'] = [401];

      final response = await dio.get<void>('protected');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(adapter.requests, hasLength(2)); // original + exactly one retry
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer refreshed-token',
      );
    });

    test('a 401 that persists after the retry does not trigger a second refresh (no infinite loop)', () async {
      adapter.statusQueue['always401'] = [401, 401];

      await expectLater(
        dio.get<void>('always401'),
        throwsA(isA<DioException>()),
      );

      expect(refreshCalls, 1);
      expect(
        adapter.requests,
        hasLength(2),
      ); // original + exactly one retry, then it gave up
    });

    test('refresh failure propagates the original error and invokes onSessionRevoked', () async {
      refreshSucceeds = false;
      adapter.statusQueue['protected'] = [401];

      await expectLater(
        dio.get<void>('protected'),
        throwsA(isA<DioException>()),
      );

      expect(refreshCalls, 1);
      expect(sessionRevokedCalls, 1);
      expect(
        adapter.requests,
        hasLength(1),
      ); // no retry attempted after a failed refresh
    });

    test('concurrent 401s across multiple requests share exactly one refresh operation (single-flight)', () async {
      adapter.statusQueue['a'] = [401];
      adapter.statusQueue['b'] = [401];
      adapter.statusQueue['c'] = [401];

      final responses = await Future.wait([
        dio.get<void>('a'),
        dio.get<void>('b'),
        dio.get<void>('c'),
      ]);

      expect(responses.every((r) => r.statusCode == 200), isTrue);
      expect(refreshCalls, 1);
    });

    test('a 401 after a successful refresh triggers a second, independent refresh (not stuck reusing the stale one)', () async {
      adapter.statusQueue['protected'] = [401];
      await dio.get<void>('protected');
      expect(refreshCalls, 1);

      adapter.statusQueue['protected'] = [401];
      await dio.get<void>('protected');
      expect(refreshCalls, 2);
    });

    for (final exemptPath in ['auth/login', 'auth/register', 'auth/refresh']) {
      test(
        '401 on $exemptPath does not trigger a refresh attempt (would be meaningless/recursive)',
        () async {
          adapter.statusQueue[exemptPath] = [401];

          await expectLater(
            dio.get<void>(exemptPath),
            throwsA(isA<DioException>()),
          );

          expect(refreshCalls, 0);
          expect(sessionRevokedCalls, 0);
        },
      );
    }
  });
}
