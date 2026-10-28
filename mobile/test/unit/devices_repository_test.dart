import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/onboarding/data/devices_api.dart';
import 'package:aesthetic_coach/features/onboarding/data/devices_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDevicesApi implements DevicesApiClient {
  Object? registerDeviceError;
  String? lastRegisteredToken;

  @override
  Future<void> registerDevice(String pushToken) async {
    lastRegisteredToken = pushToken;
    if (registerDeviceError != null) throw registerDeviceError!;
  }
}

DioException _dioError({required int statusCode, Map<String, dynamic>? data}) {
  final options = RequestOptions(path: 'devices');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('DevicesRepository', () {
    late _FakeDevicesApi fakeApi;
    late DevicesRepository repository;

    setUp(() {
      fakeApi = _FakeDevicesApi();
      repository = DevicesRepository(fakeApi);
    });

    test('registerDevice forwards the exact token to the API', () async {
      await repository.registerDevice('fcm-token-abc123');

      expect(fakeApi.lastRegisteredToken, 'fcm-token-abc123');
    });

    test('registerDevice with a network error throws NetworkFailure', () async {
      fakeApi.registerDeviceError = DioException(
        requestOptions: RequestOptions(path: 'devices'),
        type: DioExceptionType.connectionError,
      );

      await expectLater(
        repository.registerDevice('x'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test(
      'registerDevice with a 422 throws ValidationFailure with field details',
      () async {
        fakeApi.registerDeviceError = _dioError(
          statusCode: 422,
          data: {
            'error': {
              'code': 'validation_failed',
              'message': 'The given data was invalid.',
              'details': {
                'pushToken': ['The push token field is required.'],
              },
            },
          },
        );

        await expectLater(
          repository.registerDevice(''),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.fieldErrors['pushToken'],
              'fieldErrors[pushToken]',
              ['The push token field is required.'],
            ),
          ),
        );
      },
    );

    test('registerDevice with an expired session throws AuthFailure', () async {
      fakeApi.registerDeviceError = _dioError(
        statusCode: 401,
        data: {
          'error': {'code': 'unauthenticated', 'message': 'Unauthenticated.'},
        },
      );

      await expectLater(
        repository.registerDevice('x'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('registerDevice against a device with no device claim throws ServerFailure (404)', () async {
      fakeApi.registerDeviceError = _dioError(statusCode: 404);

      await expectLater(
        repository.registerDevice('x'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('registerDevice with a 429 throws RateLimitedFailure', () async {
      fakeApi.registerDeviceError = _dioError(statusCode: 429);

      await expectLater(
        repository.registerDevice('x'),
        throwsA(isA<RateLimitedFailure>()),
      );
    });

    test(
      'registerDevice with an unexpected 500 throws ServerFailure',
      () async {
        fakeApi.registerDeviceError = _dioError(statusCode: 500);

        await expectLater(
          repository.registerDevice('x'),
          throwsA(isA<ServerFailure>()),
        );
      },
    );
  });
}
