<?php

namespace App\Modules\Auth\Models;

use App\Modules\Auth\Enums\Sex;
use App\Modules\Auth\Enums\UnitPreference;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

#[Fillable(['name', 'email', 'password_hash', 'timezone', 'unit_preference', 'date_of_birth', 'sex', 'height_cm', 'dietary_restrictions'])]
#[Hidden(['password_hash'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, SoftDeletes;

    /**
     * A transient, request-scoped value set by AuthServiceProvider's `jwt`
     * guard callback from the access token's `did` claim (never persisted
     * -- see that callback's own docblock). Declared as a real PHP
     * property, not left as a dynamic one: Eloquent's `__set()` magic
     * method routes any *undeclared* property assignment into its
     * attribute-tracking/dirty-diffing system, which would make a later
     * `save()` call (e.g. ProfileService::updateProfile()) try to persist
     * it as a `users` column that doesn't exist.
     */
    public ?int $currentDeviceId = null;

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
            'unit_preference' => UnitPreference::class,
            'date_of_birth' => 'date',
            'sex' => Sex::class,
            'dietary_restrictions' => 'array',
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
     * @return HasMany<OAuthIdentity>
     */
    public function oauthIdentities(): HasMany
    {
        return $this->hasMany(OAuthIdentity::class);
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
