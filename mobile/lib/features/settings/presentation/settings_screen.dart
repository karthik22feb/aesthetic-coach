import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../profile/application/profile_notifier.dart';
import '../../profile/application/profile_state.dart';
import '../../profile/data/models/profile_enums.dart';
import '../application/theme_mode_notifier.dart';

/// docs/screens/settings.md, scoped to exactly [TASK_BREAKDOWN.md § Sprint
/// 2, Task 3]'s "basic" slice -- theme and unit preference only.
///
/// docs/features/settings.md's own Release Phase table splits this
/// feature explicitly: "basic: theme, units" lands in Sprint 2 (this
/// task); "finalized: notification preferences, data export, account
/// deletion" is Sprint 6. The full grouped-list layout in
/// docs/screens/settings.md (Notifications, Devices & Sessions, Privacy
/// & Data, Account/Logout, About/Help) is that later, finalized version
/// -- none of it is built here. Notifications has no backend yet
/// (Sprint 5); export/delete-account have no backend yet (Sprint 6).
/// Devices & Sessions and Logout *do* already have working backends
/// (Sprint 1), but adding UI for them is outside this task's scope --
/// left for whichever session finalizes Settings.
///
/// Unit preference is NOT a local-only setting: it's the same
/// server-backed `users.unit_preference` column already editable from
/// the Profile screen (see ProfileRepository). This screen reuses
/// [profileNotifierProvider] directly rather than introducing a second,
/// divergent copy of that state -- see this task's PR description for
/// why docs/features/settings.md's Business Rules sentence ("Theme/unit
/// preference are device-local... not synced via server") is corrected
/// in the same PR: it was accurate for theme but not for unit
/// preference, which Sprint 2 Task 1/2 already shipped as server-backed.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final profileState = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Theme')),
          SegmentedButton<ThemeMode>(
            key: const Key('settings_theme_field'),
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(selection.first),
          ),
          const SizedBox(height: 24),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Unit preference'),
          ),
          _UnitPreferenceControl(profileState: profileState),
        ],
      ),
    );
  }
}

class _UnitPreferenceControl extends ConsumerStatefulWidget {
  const _UnitPreferenceControl({required this.profileState});

  final ProfileState profileState;

  @override
  ConsumerState<_UnitPreferenceControl> createState() =>
      _UnitPreferenceControlState();
}

class _UnitPreferenceControlState
    extends ConsumerState<_UnitPreferenceControl> {
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final state = widget.profileState;

    if (state.status == ProfileStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (state.status == ProfileStatus.error || state.profile == null) {
      return Text(
        key: const Key('settings_unit_preference_error'),
        'Unable to load unit preference.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    final current = state.profile!.unitPreference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null) ...[
          Text(
            key: const Key('settings_unit_preference_save_error'),
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        SegmentedButton<UnitPreference>(
          key: const Key('settings_unit_preference_field'),
          segments: const [
            ButtonSegment(value: UnitPreference.metric, label: Text('Metric')),
            ButtonSegment(
              value: UnitPreference.imperial,
              label: Text('Imperial'),
            ),
          ],
          selected: {current},
          onSelectionChanged: _isSubmitting
              ? null
              : (selection) => _submit(selection.first),
        ),
      ],
    );
  }

  Future<void> _submit(UnitPreference value) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Partial PATCH -- only the field this screen owns, per
      // UpdateProfileRequest's `sometimes` semantics. No need to load or
      // resend the rest of the profile just to flip one setting.
      await ref.read(profileNotifierProvider.notifier).updateProfile({
        'unitPreference': value.name,
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(failure));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
