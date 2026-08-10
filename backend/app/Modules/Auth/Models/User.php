<?php

namespace App\Modules\Auth\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

#[Fillable(['name', 'email', 'password_hash'])]
#[Hidden(['password_hash'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, SoftDeletes;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password_hash' => 'hashed',
        ];
    }

    /**
     * @return HasMany<Device>
     */
    public function devices(): HasMany
    {
        return $this->hasMany(Device::class);
    }

    /**
     * @return HasMany<AuthRefreshToken>
     */
    public function authRefreshTokens(): HasMany
    {
        return $this->hasMany(AuthRefreshToken::class);
    }

    /**
     * Laravel's Authenticatable base expects a 'password' getter for
     * framework-level password checks; the documented column is
     * 'password_hash' (Database Design section 3.1), so this bridges the two.
     */
    public function getAuthPassword(): string
    {
        return $this->password_hash;
    }
}
