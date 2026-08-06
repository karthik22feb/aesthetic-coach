# Coding Standards

**Product:** Aesthetic Coach
**Related documents:** [Backend Architecture](07-backend-architecture.md) (architectural layering — this document is the line-level style guide built on top of it) · [Mobile Architecture](08-mobile-architecture.md) · [Testing Strategy](10-testing-strategy.md) · [Git Workflow](git-workflow.md)

## Table of Contents
- [Purpose](#purpose)
- [Laravel Standards](#laravel-standards)
- [Flutter Standards](#flutter-standards)
- [General Principles](#general-principles)
- [Documentation & Commenting](#documentation--commenting)
- [Future Improvements](#future-improvements)

## Purpose
[Backend Architecture § 8](07-backend-architecture.md#8-coding-standards) and [Mobile Architecture](08-mobile-architecture.md) already establish the architectural rules (layering, DI, state management). This document is the concrete, line-level style guide that sits underneath those decisions — the "how do I actually write this class" reference for day-to-day PRs.

## Laravel Standards

### Controllers
Thin — one action method per route, no branching business logic. A controller method's body is: validate (via Form Request, injected by type-hint), call one Service method, return a Resource.
```php
public function store(StoreWorkoutRequest $request, WorkoutService $service): WorkoutResource
{
    $workout = $service->logWorkout($request->user(), $request->toDto());
    return new WorkoutResource($workout);
}
```
A controller method exceeding ~15 lines is a signal that logic belongs in the Service instead.

### Services
Own business logic; named `{Domain}Service` (`WorkoutService`, `DailyFitnessScoreService`). One public method per use case, not one god-method with flags (`logWorkout()` and `updateWorkout()` are separate methods, never `saveWorkout($isUpdate)`). Services depend on Repositories/Eloquent and other Services via constructor injection only — never resolve dependencies via `app()->make()` inside a method body.

### Repositories
Used where query complexity or reuse justifies the indirection (`Workouts`, `Nutrition`, `Coaching` modules per [Backend Architecture § 2](07-backend-architecture.md#2-layering--responsibilities)); simple CRUD modules query Eloquent directly from the Service. A Repository method returns Eloquent models or Collections, never arrays — keep type safety through the stack.

### DTOs
Used at service-method boundaries once a payload exceeds ~3 fields, as readonly PHP 8 classes (or `spatie/laravel-data` objects), not associative arrays:
```php
final readonly class LogWorkoutDto
{
    public function __construct(
        public string $clientUuid,
        public string $name,
        public ?int $templateId,
        public CarbonImmutable $startedAt,
        public CarbonImmutable $completedAt,
        /** @var WorkoutExerciseDto[] */
        public array $exercises,
    ) {}
}
```
Constructed via a `Request::toDto()` method or a dedicated mapper — never passed as a raw `$request->all()` array into a Service.

### Form Requests
One per mutating endpoint, named `{Verb}{Resource}Request` (`StoreWorkoutRequest`, `UpdateGoalRequest`). `authorize()` performs ownership/role checks where applicable (deferring to a Policy for anything non-trivial); `rules()` is the single source of truth for validation — no duplicate validation in the Service.

### Events
Named in past tense (`WorkoutCompleted`, `HabitLogged`) per [Backend Architecture § 5](07-backend-architecture.md#5-events); carry only the data listeners need (typically the affected model plus the acting user), not the entire request payload.

### Queues
Jobs named `{Verb}{Noun}Job` (`GenerateWeeklyReviewJob`, `SendPushNotificationJob`); every job implements `ShouldQueue`, specifies an explicit `$queue` property matching one of the three named queues in [Backend Architecture § 4](07-backend-architecture.md#4-queues), and is idempotent — safe to run twice with the same input.

### Policies
One per resource model (`WorkoutPolicy`, `GoalPolicy`), registered explicitly (never relying on Laravel's naming-convention auto-discovery alone, to keep authorization mapping greppable). Every method checks ownership at minimum: `return $workout->user_id === $user->id;` — never trust a resource ID alone.

### Validation
Rules live in Form Requests, expressed with Laravel's rule objects/enums where possible rather than raw strings (`Rule::enum(WorkoutStatus::class)` not `'in:in_progress,completed'`) for refactor-safety.

### Exception Handling
Domain-specific exceptions (`InsufficientAiBudgetException`, `RefreshTokenReuseException`) extend a common `AppException` base that maps to the standard error envelope ([API Specification § 4](05-api-specification.md#4-error-response-format)) via a single exception-to-response mapper in the global handler — individual controllers never manually construct error JSON.

### Logging
Structured (`Log::info('workout.completed', ['workoutId' => $id, 'userId' => $userId])`), never string-interpolated messages that bury data in unparseable text. Never log request bodies containing passwords/tokens — enforced by the sanitizer described in [Monitoring & Logging § Log Aggregation](13-monitoring-logging.md#7-log-aggregation).

## Flutter Standards

### Folder Structure
Feature-first per [Mobile Architecture § 2](08-mobile-architecture.md#2-folder-organization) — restated here as a hard rule: a new file belongs under `features/{feature}/{data,application,presentation}/`, never a top-level `lib/screens/` or `lib/models/` catch-all.

### Riverpod Patterns
- Prefer `@riverpod` code-gen annotations over manually-written `Provider`/`StateNotifierProvider` boilerplate.
- `Notifier`/`AsyncNotifier` classes are named `{Feature}Notifier` (`ActiveWorkoutNotifier`), exposing intention-revealing methods (`logSet()`, not `updateState()`).
- Widgets read state via `ref.watch`, trigger actions via `ref.read(...).notifier).method()` — never call `ref.watch` inside a callback (a common Riverpod misuse that breaks reactivity).
- Providers are `family`-parameterized when scoped to an entity ID (`workoutProvider(workoutId)`), never a single global provider mutated in place for different entities.

### Widget Organization
Screens (`presentation/screens/`) compose smaller widgets (`presentation/widgets/`) rather than one 500-line `build()` method; any widget subtree reused across 2+ screens is promoted to `shared/widgets/` (the design-system component library, [UI/UX Design System § 3](06-ui-ux-design-system.md#3-core-components)).

### Naming Conventions
`PascalCase` for classes/widgets, `camelCase` for methods/variables, files `snake_case.dart` matching their primary class in `snake_case`. Provider variables end in `Provider` (`activeWorkoutProvider`), Notifier classes end in `Notifier`.

### Error Handling
Repositories/data sources throw typed `Failure`s ([Mobile Architecture § 7](08-mobile-architecture.md#7-error-handling)), never raw `Exception`; presentation-layer code never catches a raw exception type from a data source, only the typed `Failure` sealed class.

### Testing Practices
Every `Notifier` has a unit test using `ProviderContainer` overrides (no widget pump needed, per [Testing Strategy § Unit Testing](10-testing-strategy.md#3-unit-testing)); every shared widget has a golden test in light + dark theme ([Testing Strategy § Widget Testing](10-testing-strategy.md#4-widget-testing)); test file mirrors source file path under `test/`.

## General Principles

- **SOLID:** applied pragmatically, not dogmatically — Single Responsibility drives the Controller/Service/Repository split above; Dependency Inversion is why `AiProviderInterface` exists ([AI Coaching Engine § 6](09-ai-coaching-engine.md#6-model-abstraction-layer)) and why mobile repositories sit behind interfaces DI can swap in tests. Open/Closed is not used as an excuse to pre-build extension points nobody asked for — see [PRD's anti-over-engineering stance](01-prd.md) implicit throughout this doc set.
- **DRY, with judgment:** three similar lines is not a violation; a third near-duplicate abstraction attempt is the trigger to extract, not the first. This mirrors the project-wide instruction against premature abstraction.
- **Clean Code:** functions do one thing; names are intention-revealing enough that comments explaining *what* code does are unnecessary (see Documentation & Commenting below); guard clauses over deep nesting.
- **No dead code:** unused code is deleted, not commented out "in case we need it later" — git history is the record of what used to exist.

## Documentation & Commenting

- **Docblocks** on public Service/Repository methods where the *why* isn't obvious from the signature — not on every method reflexively, and never restating the method name in prose.
- **Comments** explain non-obvious *why* (a workaround, a subtle invariant, a business-rule reference like `// BR-3: reuse triggers family revocation`) — never *what* the next line does.
- **README per module** is not required at the individual Laravel module / Flutter feature level — the docs in this repository (particularly [Feature Specifications](features/) and [Backend](07-backend-architecture.md)/[Mobile Architecture](08-mobile-architecture.md)) are the source of truth for intent; code comments stay local and implementation-specific.
- **PR descriptions**, not code comments, are where "what changed and why" for a specific change belongs — per [Git Workflow](git-workflow.md).

## Future Improvements
Automated enforcement: expand the Larastan/PHPStan ruleset and a custom Dart lint set to mechanically catch violations of the patterns above (e.g., a lint rule flagging `app()->make()` calls outside service providers) rather than relying on code review alone.
