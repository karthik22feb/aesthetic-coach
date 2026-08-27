import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../application/profile_notifier.dart';
import '../application/profile_state.dart';
import '../data/models/profile_enums.dart';
import '../data/models/user_profile.dart';
import 'edit_profile_sheet.dart';

/// docs/screens/profile.md. Renders the subset of that spec backed by
/// data that actually exists yet: identity fields and the editable
/// fields from [ProfileApi] (`GET/PATCH /me`). The summary stat row
/// (total workouts, longest streak), the Body Measurements / Progress
/// Photos entry points, and the gear-icon link to Settings are all
/// deliberately NOT implemented here -- they depend on the Workout
/// Engine, Habits, Body Measurements, Progress Photos, and Settings
/// screens/modules, none of which exist yet (see this session's
/// checkpoint report for the full reasoning). Nothing here fabricates
/// placeholder data for those.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        // Kept in the AppBar (always on-screen) rather than as a button
        // at the end of the scrollable field list below -- the list can
        // be taller than the viewport on smaller devices, which would
        // make the only edit affordance require scrolling to reach.
        actions: profileState.status == ProfileStatus.loaded
            ? [
                IconButton(
                  key: const Key('profile_edit_button'),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profile',
                  onPressed: () => _openEditSheet(context, profile!),
                ),
              ]
            : null,
      ),
      body: switch (profileState.status) {
        ProfileStatus.loading => const Center(
          child: CircularProgressIndicator(
            key: Key('profile_loading_indicator'),
          ),
        ),
        ProfileStatus.error => _ErrorView(failure: profileState.failure!),
        ProfileStatus.loaded => _ProfileView(profile: profile!),
      },
    );
  }

  void _openEditSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProfileSheet(profile: profile),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              key: const Key('profile_error_text'),
              _messageFor(failure),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('profile_retry_button'),
              onPressed: () =>
                  ref.read(profileNotifierProvider.notifier).loadProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _messageFor(Failure failure) {
    return switch (failure) {
      AuthFailure(:final message) => message,
      ValidationFailure(:final message) => message,
      RateLimitedFailure(:final message) => message,
      NetworkFailure(:final message) => message,
      ServerFailure(:final message) => message,
    };
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                key: const Key('profile_avatar_initials'),
                _initialsFor(profile.name),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key: const Key('profile_name_text'),
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    key: const Key('profile_email_text'),
                    profile.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Email is display-only: PATCH /me's backend column allowlist
        // never includes it, and no form field for it exists anywhere
        // in this feature -- see UpdateProfileSheet.
        const Text(
          'Email cannot be changed here.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const Divider(height: 32),
        ListTile(
          key: const Key('profile_field_timezone'),
          leading: const Icon(Icons.public),
          title: const Text('Timezone'),
          subtitle: Text(profile.timezone),
        ),
        ListTile(
          key: const Key('profile_field_unit_preference'),
          leading: const Icon(Icons.straighten),
          title: const Text('Unit preference'),
          subtitle: Text(_labelForUnitPreference(profile.unitPreference)),
        ),
        ListTile(
          key: const Key('profile_field_date_of_birth'),
          leading: const Icon(Icons.cake_outlined),
          title: const Text('Date of birth'),
          subtitle: Text(profile.dateOfBirth ?? 'Not set'),
        ),
        ListTile(
          key: const Key('profile_field_sex'),
          leading: const Icon(Icons.wc),
          title: const Text('Sex'),
          subtitle: Text(_labelForSex(profile.sex)),
        ),
        ListTile(
          key: const Key('profile_field_height'),
          leading: const Icon(Icons.height),
          title: const Text('Height'),
          subtitle: Text(
            profile.heightCm != null
                ? '${profile.heightCm!.toStringAsFixed(1)} cm'
                : 'Not set',
          ),
        ),
        ListTile(
          key: const Key('profile_field_dietary_restrictions'),
          leading: const Icon(Icons.restaurant_outlined),
          title: const Text('Dietary restrictions'),
          subtitle: Text(
            profile.dietaryRestrictions.isEmpty
                ? 'None'
                : profile.dietaryRestrictions.join(', '),
          ),
        ),
      ],
    );
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }

  String _labelForUnitPreference(UnitPreference value) => switch (value) {
    UnitPreference.metric => 'Metric',
    UnitPreference.imperial => 'Imperial',
  };

  String _labelForSex(BiologicalSex? value) => switch (value) {
    BiologicalSex.male => 'Male',
    BiologicalSex.female => 'Female',
    BiologicalSex.unspecified => 'Unspecified',
    null => 'Not set',
  };
}
