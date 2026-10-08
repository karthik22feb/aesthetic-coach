import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../auth/application/auth_notifier.dart';
import '../../profile/data/models/profile_enums.dart';
import '../application/onboarding_notifier.dart';
import '../application/onboarding_state.dart';
import '../data/models/onboarding_enums.dart';

/// Sprint 2, Task 5 -- docs/features/onboarding.md's Profile Basics,
/// Goal Selection, and Experience Level steps, hosted as "a single
/// onboarding route... not separate bottom-nav destinations" (that
/// doc's Screen List) via one [OnboardingFlowScreen] that switches its
/// body on [OnboardingState.step], rather than three separate go_router
/// routes.
///
/// Reached only immediately after a fresh registration in this app
/// session (router.dart's redirect guard, gated on
/// [AuthState.justRegistered]) -- **not** resumable across an app
/// restart. docs/features/onboarding.md's own Edge Cases say progress
/// should persist "server-side via the same PATCH /me/POST /goals
/// calls, not a separate onboarding-state table," which implicitly
/// assumes a way to tell, on the *next* app launch, whether a given user
/// still needs onboarding -- no such signal exists yet (no `GET
/// /goals`, no onboarding-completion field anywhere in the documented
/// API). Full cross-restart resume is therefore a known, flagged gap
/// for this task, not something silently half-implemented -- see this
/// session's report and ENGINEERING_DECISION_LOG.md.
///
/// The "Meet Your Coach" AI step (Task 6) and the notification-
/// permission prompt (Task 7) are separate, not-yet-built steps this
/// screen does not attempt to anticipate -- finishing the Experience
/// Level step below goes straight to Home, per this task's own scope
/// boundary.
class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(state.step)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: LinearProgressIndicator(
                key: const Key('onboarding_progress_indicator'),
                value:
                    (_stepIndex(state.step) + 1) / OnboardingStep.values.length,
              ),
            ),
            Expanded(
              child: switch (state.step) {
                OnboardingStep.profileBasics => const _ProfileBasicsStep(),
                OnboardingStep.goalSelection => const _GoalSelectionStep(),
                OnboardingStep.experienceLevel => const _ExperienceLevelStep(),
              },
            ),
          ],
        ),
      ),
    );
  }

  int _stepIndex(OnboardingStep step) => OnboardingStep.values.indexOf(step);

  String _titleFor(OnboardingStep step) => switch (step) {
    OnboardingStep.profileBasics => 'Tell us about you',
    OnboardingStep.goalSelection => 'What\'s your main goal?',
    OnboardingStep.experienceLevel => 'Your experience',
  };
}

/// F-ONB-01: unit preference, timezone (editable; not auto-detected --
/// no timezone-detection dependency exists in this project yet, see
/// this session's report), and optional DOB/sex/height. Field widgets
/// deliberately mirror EditProfileSheet's (features/profile/presentation/
/// edit_profile_sheet.dart) exactly, since this collects the same
/// underlying `PATCH /me` fields.
class _ProfileBasicsStep extends ConsumerStatefulWidget {
  const _ProfileBasicsStep();

  @override
  ConsumerState<_ProfileBasicsStep> createState() => _ProfileBasicsStepState();
}

class _ProfileBasicsStepState extends ConsumerState<_ProfileBasicsStep> {
  final _timezoneController = TextEditingController(text: 'UTC');
  final _heightController = TextEditingController();
  UnitPreference _unitPreference = UnitPreference.metric;
  BiologicalSex? _sex;
  String? _dateOfBirth;

  @override
  void dispose() {
    _timezoneController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final isSubmitting = state.isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.failure != null) ...[
            Text(
              key: const Key('onboarding_profile_basics_error_text'),
              _messageFor(state.failure!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            key: const Key('onboarding_timezone_field'),
            controller: _timezoneController,
            enabled: !isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Timezone',
              hintText: 'e.g. Asia/Kolkata',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unit preference',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<UnitPreference>(
            key: const Key('onboarding_unit_preference_field'),
            segments: const [
              ButtonSegment(
                value: UnitPreference.metric,
                label: Text('Metric'),
              ),
              ButtonSegment(
                value: UnitPreference.imperial,
                label: Text('Imperial'),
              ),
            ],
            selected: {_unitPreference},
            onSelectionChanged: isSubmitting
                ? null
                : (selection) =>
                      setState(() => _unitPreference = selection.first),
          ),
          const SizedBox(height: 16),
          ListTile(
            key: const Key('onboarding_dob_button'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Date of birth (optional)'),
            subtitle: Text(_dateOfBirth ?? 'Not set'),
            onTap: isSubmitting ? null : _pickDateOfBirth,
          ),
          DropdownButtonFormField<BiologicalSex?>(
            key: const Key('onboarding_sex_field'),
            initialValue: _sex,
            decoration: const InputDecoration(labelText: 'Sex (optional)'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Not set')),
              DropdownMenuItem(value: BiologicalSex.male, child: Text('Male')),
              DropdownMenuItem(
                value: BiologicalSex.female,
                child: Text('Female'),
              ),
              DropdownMenuItem(
                value: BiologicalSex.unspecified,
                child: Text('Unspecified'),
              ),
            ],
            onChanged: isSubmitting
                ? null
                : (value) => setState(() => _sex = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('onboarding_height_field'),
            controller: _heightController,
            enabled: !isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Height in cm (optional)',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboarding_profile_basics_continue_button'),
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final latestAllowed = DateTime(now.year - 18, now.month, now.day);
    final earliestAllowed = DateTime(now.year - 100, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: latestAllowed,
      firstDate: earliestAllowed,
      lastDate: latestAllowed,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = _formatDate(picked));
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _submit() {
    final heightText = _heightController.text.trim();
    ref.read(onboardingNotifierProvider.notifier).submitProfileBasics({
      'timezone': _timezoneController.text.trim(),
      'unitPreference': _unitPreference.name,
      'dateOfBirth': _dateOfBirth,
      'sex': _sex?.name,
      'heightCm': heightText.isEmpty ? null : double.tryParse(heightText),
    });
  }

  String _messageFor(Failure failure) => switch (failure) {
    AuthFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    RateLimitedFailure(:final message) => message,
    NetworkFailure(:final message) => message,
    ServerFailure(:final message) => message,
  };
}

/// F-ONB-02: primary goal type. A default, human-readable title is
/// generated per [GoalType] rather than collecting free-text from the
/// user -- the functional requirement is to collect the *type*, and
/// docs/features/onboarding.md's skip-default edge case already
/// establishes that a synthesized title (not user-authored text) is an
/// acceptable shape for this field.
class _GoalSelectionStep extends ConsumerStatefulWidget {
  const _GoalSelectionStep();

  @override
  ConsumerState<_GoalSelectionStep> createState() => _GoalSelectionStepState();
}

class _GoalSelectionStepState extends ConsumerState<_GoalSelectionStep> {
  GoalType? _selected;

  static const _titleFor = {
    GoalType.strength: 'Build strength',
    GoalType.bodyComposition: 'Improve body composition',
    GoalType.habit: 'Build a consistent routine',
    GoalType.event: 'Prepare for an event',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final isSubmitting = state.isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.failure != null) ...[
            Text(
              key: const Key('onboarding_goal_selection_error_text'),
              _messageFor(state.failure!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          RadioGroup<GoalType>(
            groupValue: _selected,
            onChanged: isSubmitting
                ? (_) {}
                : (value) => setState(() => _selected = value),
            child: Column(
              children: [
                for (final type in GoalType.values)
                  RadioListTile<GoalType>(
                    key: Key('onboarding_goal_option_${type.wireValue}'),
                    title: Text(_titleFor[type]!),
                    value: type,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboarding_goal_selection_continue_button'),
            onPressed: isSubmitting || _selected == null ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('onboarding_goal_selection_skip_button'),
            onPressed: isSubmitting ? null : _skip,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final type = _selected!;
    ref
        .read(onboardingNotifierProvider.notifier)
        .selectGoal(type: type, title: _titleFor[type]!);
  }

  void _skip() {
    ref.read(onboardingNotifierProvider.notifier).skipGoal();
  }

  String _messageFor(Failure failure) => switch (failure) {
    AuthFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    RateLimitedFailure(:final message) => message,
    NetworkFailure(:final message) => message,
    ServerFailure(:final message) => message,
  };
}

/// F-ONB-03: experience level + equipment access, local-only (see
/// OnboardingState.selectedExperienceLevel's docblock). The final step
/// in this task's scope -- "Finish" clears
/// [AuthState.justRegistered] and navigates to Home directly, since
/// "Meet Your Coach" (Task 6) and the notification prompt (Task 7)
/// don't exist yet.
class _ExperienceLevelStep extends ConsumerStatefulWidget {
  const _ExperienceLevelStep();

  @override
  ConsumerState<_ExperienceLevelStep> createState() =>
      _ExperienceLevelStepState();
}

class _ExperienceLevelStepState extends ConsumerState<_ExperienceLevelStep> {
  ExperienceLevel? _selected;
  final Set<String> _equipment = {};

  static const _equipmentOptions = [
    'Bodyweight only',
    'Dumbbells',
    'Barbell',
    'Full gym access',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<ExperienceLevel>(
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value),
            child: Column(
              children: [
                for (final level in ExperienceLevel.values)
                  RadioListTile<ExperienceLevel>(
                    key: Key('onboarding_experience_option_${level.name}'),
                    title: Text(_labelFor(level)),
                    value: level,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Equipment you have access to',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (final option in _equipmentOptions)
            CheckboxListTile(
              key: Key(
                'onboarding_equipment_option_${option.toLowerCase().replaceAll(' ', '_')}',
              ),
              title: Text(option),
              value: _equipment.contains(option),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _equipment.add(option);
                } else {
                  _equipment.remove(option);
                }
              }),
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboarding_finish_button'),
            onPressed: _selected == null ? null : _finish,
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  String _labelFor(ExperienceLevel level) => switch (level) {
    ExperienceLevel.beginner => 'Beginner',
    ExperienceLevel.intermediate => 'Intermediate',
    ExperienceLevel.advanced => 'Advanced',
  };

  void _finish() {
    ref
        .read(onboardingNotifierProvider.notifier)
        .setExperienceLevel(level: _selected!, equipment: _equipment.toList());
    ref.read(authNotifierProvider.notifier).clearJustRegistered();
    context.go('/home');
  }
}
