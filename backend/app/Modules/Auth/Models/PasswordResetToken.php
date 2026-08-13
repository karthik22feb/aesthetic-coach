<?php

namespace App\Modules\Auth\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

/**
 * Database Design section 3.1: `email` PK, `token_hash` CHAR(64) (SHA-256 of
 * the plaintext token, which is never stored), `expires_at` TIMESTAMP. One
 * row per email -- a new request overwrites any prior unused token for that
 * email (see AuthService::forgotPassword()), so an old, un-clicked reset
 * link stops working the moment a new one is requested, not just on use.
 */
#[Fillable(['email', 'token_hash', 'expires_at'])]
class PasswordResetToken extends Model
{
    protected $primaryKey = 'email';

    protected $keyType = 'string';

    public $incrementing = false;

    public $timestamps = false;

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
        ];
    }
}
