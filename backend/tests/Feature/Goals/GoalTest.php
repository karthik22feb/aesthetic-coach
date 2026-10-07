<?php

use App\Modules\Auth\Models\User;
use App\Modules\Goals\Enums\GoalStatus;
use App\Modules\Goals\Enums\GoalType;
use App\Modules\Goals\Models\Goal;
use Illuminate\Support\Carbon;

/*
|--------------------------------------------------------------------------
| Sprint 2, Task 9 -- Goals model coverage
|--------------------------------------------------------------------------
|
| Task 4 shipped only the `goals` migration + Eloquent model (no HTTP
| endpoint yet -- `POST /goals` is Sprint 4 scope per docs/features/goals.md)
| and was verified post-merge via a manual Tinker round-trip only, per
| MASTER_IMPLEMENTATION_PLAN.md. These are the automated Pest Feature tests
| that were missing: model creation, the documented enum casts, the
| user()/goals() relationship pair, cross-user isolation, and the
| idempotency-adjacent checks applicable to a model with no HTTP surface
| and no natural unique key yet (see the last two tests below for why the
| literal "clientUuid replay" criterion from docs/10-testing-strategy.md
| section 5 doesn't apply here).
|
*/

test('a goal can be created with the required fields', function () {
    $user = User::factory()->create();

    $goal = Goal::factory()->for($user)->create([
        'type' => GoalType::Habit,
        'title' => 'Walk 10,000 steps daily',
    ]);

    expect($goal->exists)->toBeTrue();
    expect($goal->user_id)->toBe($user->id);
    expect($goal->title)->toBe('Walk 10,000 steps daily');
    expect($goal->target_metric)->toBeNull();
    expect($goal->target_value)->toBeNull();
    expect($goal->target_date)->toBeNull();
    expect($goal->status)->toBe(GoalStatus::Active);
});

test('the type cast round-trips through every GoalType case', function (GoalType $type) {
    $goal = Goal::factory()->create(['type' => $type]);

    $fresh = Goal::find($goal->id);

    expect($fresh->type)->toBeInstanceOf(GoalType::class);
    expect($fresh->type)->toBe($type);
})->with(GoalType::cases());

test('the status cast round-trips through every GoalStatus case', function (GoalStatus $status) {
    $goal = Goal::factory()->create(['status' => $status]);

    $fresh = Goal::find($goal->id);

    expect($fresh->status)->toBeInstanceOf(GoalStatus::class);
    expect($fresh->status)->toBe($status);
})->with(GoalStatus::cases());

test('target_metric, target_value, and target_date are correctly cast when set', function () {
    $goal = Goal::factory()
        ->withTarget('bench_press_1rm_kg', 80, '2027-01-01')
        ->create(['type' => GoalType::Strength]);

    $fresh = Goal::find($goal->id);

    expect($fresh->target_metric)->toBe('bench_press_1rm_kg');
    // Laravel's `decimal:2` cast returns a formatted string, not a float --
    // asserted as a numeric value (not an exact string) since the storage
    // representation is an implementation detail, same reasoning
    // ProfileTest.php already applies to heightCm.
    expect((float) $fresh->target_value)->toBe(80.0);
    expect($fresh->target_date)->toBeInstanceOf(Carbon::class);
    expect($fresh->target_date->toDateString())->toBe('2027-01-01');
});

test('created_at is cast to a datetime instance', function () {
    $goal = Goal::factory()->create();

    expect($goal->created_at)->toBeInstanceOf(Carbon::class);
});

test('a goal belongs to its creating user via the user() relationship', function () {
    $user = User::factory()->create();
    $goal = Goal::factory()->for($user)->create();

    expect($goal->user)->toBeInstanceOf(User::class);
    expect($goal->user->is($user))->toBeTrue();
});

test("a user's goals() relationship returns only that user's own goals", function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();

    $goalsA = Goal::factory()->for($userA)->count(2)->create();
    $goalB = Goal::factory()->for($userB)->create();

    $userA->refresh();
    $userB->refresh();

    expect($userA->goals)->toHaveCount(2);
    expect($userA->goals->pluck('id')->sort()->values()->all())
        ->toBe($goalsA->pluck('id')->sort()->values()->all());
    expect($userA->goals->pluck('id'))->not->toContain($goalB->id);

    expect($userB->goals)->toHaveCount(1);
    expect($userB->goals->first()->id)->toBe($goalB->id);
});

test('force-deleting a user cascades to delete their goals', function () {
    // User::delete() is a *soft* delete (the model uses SoftDeletes) -- it
    // only sets deleted_at and never issues a real SQL DELETE, so the
    // migration's cascadeOnDelete() FK constraint cannot fire from it.
    // forceDelete() is the one operation that actually removes the row,
    // which is what this test needs to exercise the real FK behavior.
    $user = User::factory()->create();
    $goal = Goal::factory()->for($user)->create();

    $user->forceDelete();

    expect(Goal::find($goal->id))->toBeNull();
});

test('updating a goal does not attempt to write an updated_at column', function () {
    // Goal::UPDATED_AT is null because the `goals` table has no
    // updated_at column at all (see the migration) -- against real MySQL
    // (not SQLite), Eloquent attempting to write an unknown column would
    // surface as a genuine SQL error, so this test would fail loudly if
    // that constant were ever removed.
    $goal = Goal::factory()->create(['title' => 'Original title']);
    $originalCreatedAt = $goal->created_at;

    $goal->update(['title' => 'Updated title']);
    $fresh = Goal::find($goal->id);

    expect($fresh->title)->toBe('Updated title');
    expect($fresh->created_at->equalTo($originalCreatedAt))->toBeTrue();
});

test('creating two goals with identical attributes for the same user does not collide or deduplicate', function () {
    // No unique constraint exists on (user_id, type, title) -- a user may
    // legitimately want two separate goals that look identical today (e.g.
    // two independent "lose weight" goals started at different times), so
    // nothing in this model should silently merge or reject the second one.
    $user = User::factory()->create();
    $attributes = [
        'type' => GoalType::Habit,
        'title' => 'Drink more water',
    ];

    $first = Goal::factory()->for($user)->create($attributes);
    $second = Goal::factory()->for($user)->create($attributes);

    expect($first->id)->not->toBe($second->id);
    expect(Goal::where('user_id', $user->id)->count())->toBe(2);
});
