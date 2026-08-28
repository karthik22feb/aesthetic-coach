<?php

namespace App\Modules\Goals\Models;

use App\Modules\Auth\Models\User;
use App\Modules\Goals\Enums\GoalStatus;
use App\Modules\Goals\Enums\GoalType;
use Database\Factories\GoalFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'type', 'title', 'target_metric', 'target_value', 'target_date', 'status'])]
class Goal extends Model
{
    /** @use HasFactory<GoalFactory> */
    use HasFactory;

    const UPDATED_AT = null;

    /**
     * See User::newFactory()'s docblock -- convention-based factory
     * resolution doesn't account for this project's `App\Modules\*\Models`
     * nesting.
     */
    protected static function newFactory(): GoalFactory
    {
        return GoalFactory::new();
    }

    protected function casts(): array
    {
        return [
            'type' => GoalType::class,
            'target_value' => 'decimal:2',
            'target_date' => 'date',
            'status' => GoalStatus::class,
            'created_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
