<?php

namespace App\Modules\Auth\Models;

use App\Modules\Auth\Enums\OAuthProvider;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'provider', 'provider_user_id'])]
class OAuthIdentity extends Model
{
    const UPDATED_AT = null;

    // Eloquent's snake_case-of-class-name convention splits "OAuth" on
    // every capital (O-A-U-T-h), producing 'o_auth_identities' instead of
    // the migrated table name -- must be set explicitly.
    protected $table = 'oauth_identities';

    protected function casts(): array
    {
        return [
            'provider' => OAuthProvider::class,
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
