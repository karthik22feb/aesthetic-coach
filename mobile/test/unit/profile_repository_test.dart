import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/profile/data/models/profile_enums.dart';
import 'package:aesthetic_coach/features/profile/data/models/user_profile.dart';
import 'package:aesthetic_coach/features/profile/data/profile_api.dart';
import 'package:aesthetic_coach/features/profile/data/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = UserProfile(
  id: '1',
  name: 'Priya Shah',
  email: 'priya@example.com',
  emailVerified: true,
  timezone: 'UTC',
  unitPreference: UnitPreference.metric,
  dietaryRestrictions: [],
);

class _FakeProfileApi implements ProfileApiClient {
  Object? getProfileError;
  Object? updateProfileError;
  UserProfile getProfileResponse = _profile;
  UserProfile updateProfileResponse = _profile;
  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<UserProfile> getProfile() async {
    if (getProfileError != null) throw getProfileError!;
    return getProfileResponse;
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> changes) async {
    lastUpdatePayload = changes;
    if (updateProfileError != null) throw updateProfileError!;
    return updateProfileResponse;
  }
}

DioException _dioError({required int statusCode, Map<String, dynamic>? data}) {
  final options = RequestOptions(path: 'me');
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
  group('ProfileRepository', () {
    late _FakeProfileApi fakeApi;
    late ProfileRepository repository;

    setUp(() {
      fakeApi = _FakeProfileApi();
      repository = ProfileRepository(fakeApi);
    });

    test('getProfile returns the parsed profile on success', () async {
      final profile = await repository.getProfile();
      expect(profile, _profile);
    });

    test('getProfile with a network error throws NetworkFailure', () async {
      fakeApi.getProfileError = DioException(
        requestOptions: RequestOptions(path: 'me'),
        type: DioExceptionType.connectionError,
      );

      await expectLater(
        repository.getProfile(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test(
      'getProfile with an expired/invalid session throws AuthFailure',
      () async {
        fakeApi.getProfileError = _dioError(
          statusCode: 401,
          data: {
            'error': {'code': 'unauthenticated', 'message': 'Unauthenticated.'},
          },
        );

        await expectLater(repository.getProfile(), throwsA(isA<AuthFailure>()));
      },
    );

    test('updateProfile forwards the exact payload to the API', () async {
      final changes = {
        'name': 'New Name',
        'timezone': 'Asia/Kolkata',
        'unitPreference': 'imperial',
        'dateOfBirth': null,
        'sex': null,
        'heightCm': null,
        'dietaryRestrictions': <String>[],
      };

      await repository.updateProfile(changes);

      expect(fakeApi.lastUpdatePayload, changes);
    });

    test(
      'updateProfile returns the server-returned profile on success',
      () async {
        fakeApi.updateProfileResponse = const UserProfile(
          id: '1',
          name: 'Updated Name',
          email: 'priya@example.com',
          emailVerified: true,
          timezone: 'Asia/Kolkata',
          unitPreference: UnitPreference.imperial,
          dietaryRestrictions: ['vegetarian'],
        );

        final profile = await repository.updateProfile({});

        expect(profile.name, 'Updated Name');
        expect(profile.unitPreference, UnitPreference.imperial);
        expect(profile.dietaryRestrictions, ['vegetarian']);
      },
    );

    test(
      'updateProfile with a 422 throws ValidationFailure with field details',
      () async {
        fakeApi.updateProfileError = _dioError(
          statusCode: 422,
          data: {
            'error': {
              'code': 'validation_failed',
              'message': 'The given data was invalid.',
              'details': {
                'heightCm': ['The height cm must be between 50 and 250.'],
              },
            },
          },
        );

        await expectLater(
          repository.updateProfile({'heightCm': 999}),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.fieldErrors['heightCm'],
              'fieldErrors[heightCm]',
              ['The height cm must be between 50 and 250.'],
            ),
          ),
        );
      },
    );

    test('updateProfile with a 429 throws RateLimitedFailure', () async {
      fakeApi.updateProfileError = _dioError(statusCode: 429);

      await expectLater(
        repository.updateProfile({}),
        throwsA(isA<RateLimitedFailure>()),
      );
    });

    test('updateProfile with an unexpected 500 throws ServerFailure', () async {
      fakeApi.updateProfileError = _dioError(statusCode: 500);

      await expectLater(
        repository.updateProfile({}),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
