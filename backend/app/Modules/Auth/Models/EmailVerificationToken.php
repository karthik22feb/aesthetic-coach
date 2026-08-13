<?php

namespace App\Modules\Auth\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

/**
 * No email-verification token table is specified in the frozen Database
 * Design -- per this session's resolution (see ENGINEERING_DECISION_LOG.md),
 * this mirrors PasswordResetToken exactly: `email` PK, `token_hash` CHAR(64)
 * (SHA-256, plaintext never stored), `expires_at`. One row per email.
 */
#[Fillable(['email', 'token_hash', 'expires_at'])]
class EmailVerificationToken extends Model
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
