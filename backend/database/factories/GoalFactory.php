<?php

namespace Database\Factories;

use App\Modules\Auth\Models\User;
use App\Modules\Goals\Enums\GoalStatus;
use App\Modules\Goals\Enums\GoalType;
use App\Modules\Goals\Models\Goal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Goal>
 */
class GoalFactory extends Factory
{
    protected $model = Goal::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => fake()->randomElement(GoalType::cases()),
            'title' => fake()->sentence(4),
            'target_metric' => null,
            'target_value' => null,
            'target_date' => null,
            'status' => GoalStatus::Active,
        ];
    }

    /**
     * Indicate that the goal targets a specific metric (e.g. a strength or
     * body-composition goal), rather than the metric-less habit/event goals
     * onboarding defaults to.
     */
    public function withTarget(string $metric, float $value, ?string $date = null): static
    {
        return $this->state(fn (array $attributes) => [
            'target_metric' => $metric,
            'target_value' => $value,
            'target_date' => $date,
        ]);
    }

    public function achieved(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => GoalStatus::Achieved,
        ]);
    }

    public function abandoned(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => GoalStatus::Abandoned,
        ]);
    }
}
