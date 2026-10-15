import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the "Meet Your Coach" onboarding step (Sprint 2, Task 6) may
/// attempt the real first-workout AI-generation call.
///
/// docs/11-cicd-pipeline.md section 6 documents feature flags as
/// **server-driven**: "a simple `feature_flags` config/table, evaluated
/// per-user, exposed via `GET /me`'s capabilities block." That
/// capabilities block does not exist on the backend yet -- `/me`'s
/// response (ProfileResource) has no such field -- so this is a
/// hardcoded stand-in, not a real read of server state, mirroring the
/// same "resolve a documented-but-unbuilt dependency explicitly, don't
/// invent the missing piece" approach Task 5 used for `POST /goals`
/// (see ENGINEERING_DECISION_LOG.md for both).
///
/// Stays `false` through Sprint 2: the real call this gates
/// (`POST /templates/ai-generate` / `POST /coach/conversations`, per
/// docs/features/onboarding.md's APIs) depends on the Workout Engine
/// (Sprint 3) and AI Recommendations (Sprint 5) modules, neither of
/// which exist in the backend at all yet -- not even a migration, unlike
/// Goals. Flip to a real `/me`-capabilities-backed read once Sprint 5
/// actually has something for it to call.
final aiOnboardingGenerationEnabledProvider = Provider<bool>((ref) => false);
