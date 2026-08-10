<?php

namespace App\Modules\Auth\Models;

use App\Modules\Auth\Enums\Platform;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'platform', 'device_name', 'push_token', 'app_version', 'last_active_at'])]
class Device extends Model
{
    const UPDATED_AT = null;

    protected function casts(): array
    {
        return [
            'platform' => Platform::class,
            'last_active_at' => 'datetime',
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

    /**
     * @return HasMany<AuthRefreshToken, $this>
     */
    public function authRefreshTokens(): HasMany
    {
        return $this->hasMany(AuthRefreshToken::class);
    }
}
