import 'package:aesthetic_coach/core/di/profile_providers.dart';
import 'package:aesthetic_coach/core/error/failure.dart';
import 'package:aesthetic_coach/features/profile/data/models/profile_enums.dart';
import 'package:aesthetic_coach/features/profile/data/models/user_profile.dart';
import 'package:aesthetic_coach/features/profile/data/profile_repository.dart';
import 'package:aesthetic_coach/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// A controllable fake so tests can drive every branch of [ProfileScreen]
/// and [EditProfileSheet] without a real network call, matching the
/// pattern established by login_screen_test.dart's `_FakeAuthRepository`.
class _FakeProfileRepository implements ProfileRepositoryContract {
  Object? getProfileError;
  Duration? getProfileDelay;
  Object? updateProfileError;
  UserProfile getProfileResponse = _profile;
  UserProfile updateProfileResponse = _profile;
  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<UserProfile> getProfile() async {
    if (getProfileDelay != null) await Future<void>.delayed(getProfileDelay!);
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

Widget _hostedProfileScreen(_FakeProfileRepository fakeRepository) {
  return ProviderScope(
    overrides: [profileRepositoryProvider.overrideWithValue(fakeRepository)],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  group('ProfileScreen', () {
    late _FakeProfileRepository fakeRepository;

    setUp(() => fakeRepository = _FakeProfileRepository());

    testWidgets(
      'shows a loading indicator while the profile is being fetched',
      (tester) async {
        fakeRepository.getProfileDelay = const Duration(milliseconds: 200);
        await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
        await tester.pump();

        expect(
          find.byKey(const Key('profile_loading_indicator')),
          findsOneWidget,
        );

        await tester.pumpAndSettle();
      },
    );

    testWidgets('displays the loaded profile fields correctly', (tester) async {
      fakeRepository.getProfileResponse = const UserProfile(
        id: '1',
        name: 'Priya Shah',
        email: 'priya@example.com',
        emailVerified: true,
        timezone: 'Asia/Kolkata',
        unitPreference: UnitPreference.metric,
        dateOfBirth: '1997-03-14',
        sex: BiologicalSex.female,
        heightCm: 165,
        dietaryRestrictions: ['vegetarian'],
      );
      await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('Priya Shah'), findsOneWidget);
      expect(find.text('priya@example.com'), findsOneWidget);
      expect(find.text('Asia/Kolkata'), findsOneWidget);
      expect(find.text('Metric'), findsOneWidget);
      expect(find.text('1997-03-14'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('165.0 cm'), findsOneWidget);
      expect(find.text('vegetarian'), findsOneWidget);
    });

    testWidgets('displays "Not set" for nullable fields that are absent', (
      tester,
    ) async {
      await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
      await tester.pumpAndSettle();

      // _profile has no dateOfBirth/sex/heightCm and empty restrictions.
      expect(find.text('Not set'), findsNWidgets(3));
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('shows an inline error and a retry button on a load failure', (
      tester,
    ) async {
      fakeRepository.getProfileError = const NetworkFailure();
      await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_error_text')), findsOneWidget);
      expect(find.byKey(const Key('profile_retry_button')), findsOneWidget);

      fakeRepository.getProfileError = null;
      await tester.tap(find.byKey(const Key('profile_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_field_timezone')), findsOneWidget);
    });

    testWidgets(
      'email has no editable field anywhere on the screen or in the Edit Profile sheet',
      (tester) async {
        await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
        await tester.pumpAndSettle();

        // Displayed read-only on the screen itself.
        expect(find.text('priya@example.com'), findsOneWidget);
        expect(find.text('Email cannot be changed here.'), findsOneWidget);

        await tester.tap(find.byKey(const Key('profile_edit_button')));
        await tester.pumpAndSettle();

        // The sheet overlays the screen rather than replacing it, so the
        // screen's own read-only email text is still technically in the
        // tree -- the real assertion is that the *sheet* contributes no
        // additional widget bearing the email value, and that only the
        // 7 PATCH-able fields have a TextFormField/selector in the sheet
        // (name, timezone, height, and the dietary-restriction
        // add-input; unitPreference/sex/dateOfBirth use non-text
        // selectors) -- no 5th text field for email exists anywhere.
        expect(find.text('priya@example.com'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(4));
      },
    );

    testWidgets('editing and saving updates the profile and closes the sheet', (
      tester,
    ) async {
      fakeRepository.updateProfileResponse = const UserProfile(
        id: '1',
        name: 'Priya Shah',
        email: 'priya@example.com',
        emailVerified: true,
        timezone: 'Asia/Kolkata',
        unitPreference: UnitPreference.metric,
        dietaryRestrictions: [],
      );
      await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_edit_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_profile_timezone_field')),
        'Asia/Kolkata',
      );
      await tester.ensureVisible(
        find.byKey(const Key('edit_profile_save_button')),
      );
      await tester.tap(find.byKey(const Key('edit_profile_save_button')));
      await tester.pumpAndSettle();

      // Sheet closed, back on the profile view with the updated value.
      expect(find.byKey(const Key('edit_profile_save_button')), findsNothing);
      expect(find.text('Asia/Kolkata'), findsOneWidget);
      expect(fakeRepository.lastUpdatePayload?['timezone'], 'Asia/Kolkata');
    });

    testWidgets(
      'a 422 validation failure is shown inline in the sheet, which stays open',
      (tester) async {
        await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_edit_button')));
        await tester.pumpAndSettle();

        // Timezone only gets a non-empty check client-side (real IANA
        // validity is server-only, per UpdateProfileRequest's
        // `timezone:all` rule) -- an ill-formed-but-non-empty value
        // passes the client validator and genuinely reaches the fake
        // repository, exercising the server-rejection path.
        fakeRepository.updateProfileError = const ValidationFailure({
          'timezone': ['The selected timezone is invalid.'],
        });
        await tester.enterText(
          find.byKey(const Key('edit_profile_timezone_field')),
          'Not/A_Real_Zone',
        );
        await tester.ensureVisible(
          find.byKey(const Key('edit_profile_save_button')),
        );
        await tester.tap(find.byKey(const Key('edit_profile_save_button')));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastUpdatePayload, isNotNull);
        expect(find.text('The selected timezone is invalid.'), findsOneWidget);
        // Sheet is still open -- save button (only present in the sheet)
        // is still on screen, not dismissed.
        expect(
          find.byKey(const Key('edit_profile_save_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'selecting Imperial and a sex value sends the correct enum wire values',
      (tester) async {
        await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_edit_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Imperial'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('edit_profile_sex_field')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Female').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('edit_profile_save_button')),
        );
        await tester.tap(find.byKey(const Key('edit_profile_save_button')));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastUpdatePayload?['unitPreference'], 'imperial');
        expect(fakeRepository.lastUpdatePayload?['sex'], 'female');
      },
    );

    testWidgets(
      'clearing an already-set date of birth sends null, not a stale value',
      (tester) async {
        fakeRepository.getProfileResponse = const UserProfile(
          id: '1',
          name: 'Priya Shah',
          email: 'priya@example.com',
          emailVerified: true,
          timezone: 'UTC',
          unitPreference: UnitPreference.metric,
          dateOfBirth: '1997-03-14',
          dietaryRestrictions: [],
        );
        await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_edit_button')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('edit_profile_dob_clear_button')),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('edit_profile_save_button')),
        );
        await tester.tap(find.byKey(const Key('edit_profile_save_button')));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastUpdatePayload?['dateOfBirth'], isNull);
      },
    );

    testWidgets(
      'adding a dietary restriction chip includes it in the submitted payload',
      (tester) async {
        await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_edit_button')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('edit_profile_dietary_input_field')),
          'vegetarian',
        );
        await tester.tap(
          find.byKey(const Key('edit_profile_dietary_add_button')),
        );
        await tester.pump();

        expect(find.text('vegetarian'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('edit_profile_save_button')),
        );
        await tester.tap(find.byKey(const Key('edit_profile_save_button')));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastUpdatePayload?['dietaryRestrictions'], [
          'vegetarian',
        ]);
      },
    );

    testWidgets('an empty name is rejected client-side before submitting', (
      tester,
    ) async {
      await tester.pumpWidget(_hostedProfileScreen(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_edit_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('edit_profile_name_field')),
        '',
      );
      await tester.ensureVisible(
        find.byKey(const Key('edit_profile_save_button')),
      );
      await tester.tap(find.byKey(const Key('edit_profile_save_button')));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(fakeRepository.lastUpdatePayload, isNull);
    });
  });
}
