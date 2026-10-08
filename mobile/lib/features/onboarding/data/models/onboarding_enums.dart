/// Mirrors the backend's `GoalType` exactly
/// (backend/app/Modules/Goals/Enums/GoalType.php) -- unlike
/// profile_enums.dart's `UnitPreference`/`BiologicalSex`, `.name` cannot
/// be used directly for the wire value here, since Dart enum identifiers
/// can't contain underscores the way the backend's `body_composition`
/// case does -- [wireValue]/[fromWire] handle that one mismatch
/// explicitly.
enum GoalType {
  strength,
  bodyComposition,
  habit,
  event;

  String get wireValue => switch (this) {
    GoalType.strength => 'strength',
    GoalType.bodyComposition => 'body_composition',
    GoalType.habit => 'habit',
    GoalType.event => 'event',
  };

  static GoalType fromWire(String value) => switch (value) {
    'strength' => GoalType.strength,
    'body_composition' => GoalType.bodyComposition,
    'habit' => GoalType.habit,
    'event' => GoalType.event,
    _ => throw ArgumentError('Unknown GoalType wire value: $value'),
  };
}

/// Per docs/features/onboarding.md's Validation Rules -- collected during
/// the Experience Level step and carried forward in-memory for the
/// (not-yet-built) "Meet Your Coach" AI-generation step, per F-ONB-03.
/// No backend field exists for this yet, so there is nothing to map to
/// a wire value until that step is implemented.
enum ExperienceLevel { beginner, intermediate, advanced }
