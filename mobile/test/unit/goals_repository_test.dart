import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/onboarding/data/goals_api.dart';
import 'package:aesthetic_coach/features/onboarding/data/goals_repository.dart';
import 'package:aesthetic_coach/features/onboarding/data/models/goal.dart';
import 'package:aesthetic_coach/features/onboarding/data/models/onboarding_enums.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGoalsApi implements GoalsApiClient {
  Object? createGoalError;
  Goal createGoalResponse = const Goal(
    id: '1',
    type: GoalType.habit,
    title: 'Build a consistent routine',
  );
  ({GoalType type, String title})? lastCreatePayload;

  @override
  Future<Goal> createGoal({
    required GoalType type,
    required String title,
  }) async {
    lastCreatePayload = (type: type, title: title);
    if (createGoalError != null) throw createGoalError!;
    return createGoalResponse;
  }
}

DioException _dioError({required int statusCode, Map<String, dynamic>? data}) {
  final options = RequestOptions(path: 'goals');
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
  group('GoalsRepository', () {
    late _FakeGoalsApi fakeApi;
    late GoalsRepository repository;

    setUp(() {
      fakeApi = _FakeGoalsApi();
      repository = GoalsRepository(fakeApi);
    });

    test('createGoal forwards the exact type and title to the API', () async {
      await repository.createGoal(
        type: GoalType.strength,
        title: 'Build strength',
      );

      expect(fakeApi.lastCreatePayload, (
        type: GoalType.strength,
        title: 'Build strength',
      ));
    });

    test('createGoal returns the created goal on success', () async {
      fakeApi.createGoalResponse = const Goal(
        id: '42',
        type: GoalType.bodyComposition,
        title: 'Improve body composition',
      );

      final goal = await repository.createGoal(
        type: GoalType.bodyComposition,
        title: 'Improve body composition',
      );

      expect(goal.id, '42');
      expect(goal.type, GoalType.bodyComposition);
    });

    test('createGoal with a network error throws NetworkFailure', () async {
      fakeApi.createGoalError = DioException(
        requestOptions: RequestOptions(path: 'goals'),
        type: DioExceptionType.connectionError,
      );

      await expectLater(
        repository.createGoal(type: GoalType.habit, title: 'x'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test(
      'createGoal with a 422 throws ValidationFailure with field details',
      () async {
        fakeApi.createGoalError = _dioError(
          statusCode: 422,
          data: {
            'error': {
              'code': 'validation_failed',
              'message': 'The given data was invalid.',
              'details': {
                'type': ['The selected type is invalid.'],
              },
            },
          },
        );

        await expectLater(
          repository.createGoal(type: GoalType.event, title: 'x'),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.fieldErrors['type'],
              'fieldErrors[type]',
              ['The selected type is invalid.'],
            ),
          ),
        );
      },
    );

    test('createGoal with an expired session throws AuthFailure', () async {
      fakeApi.createGoalError = _dioError(
        statusCode: 401,
        data: {
          'error': {'code': 'unauthenticated', 'message': 'Unauthenticated.'},
        },
      );

      await expectLater(
        repository.createGoal(type: GoalType.habit, title: 'x'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('createGoal with a 429 throws RateLimitedFailure', () async {
      fakeApi.createGoalError = _dioError(statusCode: 429);

      await expectLater(
        repository.createGoal(type: GoalType.habit, title: 'x'),
        throwsA(isA<RateLimitedFailure>()),
      );
    });

    test('createGoal with an unexpected 500 throws ServerFailure', () async {
      fakeApi.createGoalError = _dioError(statusCode: 500);

      await expectLater(
        repository.createGoal(type: GoalType.habit, title: 'x'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('MockGoalsApi', () {
    test('createGoal succeeds without a network call and echoes the requested type/title', () async {
      final mock = MockGoalsApi();

      final goal = await mock.createGoal(
        type: GoalType.strength,
        title: 'Build strength',
      );

      expect(goal.type, GoalType.strength);
      expect(goal.title, 'Build strength');
      expect(goal.id, isNotEmpty);
    });

    test('createGoal generates a distinct id per call', () async {
      final mock = MockGoalsApi();

      final first = await mock.createGoal(type: GoalType.habit, title: 'a');
      final second = await mock.createGoal(type: GoalType.habit, title: 'b');

      expect(first.id, isNot(second.id));
    });
  });

  group('GoalType wire mapping', () {
    test('wireValue matches the backend enum exactly', () {
      expect(GoalType.strength.wireValue, 'strength');
      expect(GoalType.bodyComposition.wireValue, 'body_composition');
      expect(GoalType.habit.wireValue, 'habit');
      expect(GoalType.event.wireValue, 'event');
    });

    test('fromWire round-trips every case', () {
      for (final type in GoalType.values) {
        expect(GoalType.fromWire(type.wireValue), type);
      }
    });

    test('fromWire rejects an unknown value', () {
      expect(() => GoalType.fromWire('not_a_real_type'), throwsArgumentError);
    });
  });
}
