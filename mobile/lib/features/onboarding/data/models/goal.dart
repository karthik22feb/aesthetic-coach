import 'onboarding_enums.dart';

/// Mirrors the subset of the backend's (not-yet-built) `POST /goals`
/// response that this feature actually needs -- per
/// docs/features/goals.md and backend/app/Modules/Goals/Models/Goal.php.
/// Kept intentionally minimal (no `targetMetric`/`targetValue`/
/// `targetDate`): Task 5's onboarding goal-selection step only collects
/// [type], never a numeric target -- see
/// docs/features/onboarding.md's Functional Requirements (F-ONB-02).
class Goal {
  const Goal({required this.id, required this.type, required this.title});

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      type: GoalType.fromWire(json['type'] as String),
      title: json['title'] as String,
    );
  }

  final String id;
  final GoalType type;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      other.id == id &&
      other.type == type &&
      other.title == title;

  @override
  int get hashCode => Object.hash(id, type, title);
}
