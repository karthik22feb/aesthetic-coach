<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Models\User;

/**
 * Kept separate from AuthService -- that class owns the authentication
 * flows (register/login/refresh/logout); this owns profile CRUD, per
 * docs/features/profile.md. Both operate on the same User model (there
 * is no separate Profile module in the frozen
 * docs/07-backend-architecture.md section 1 folder listing).
 */
class ProfileService
{
    /**
     * @param  array<string, mixed>  $attributes  Already column-mapped by
     *                                            UpdateProfileRequest::toDto() --
     *                                            only the keys the client
     *                                            actually sent (partial update).
     */
    public function updateProfile(User $user, array $attributes): User
    {
        $user->fill($attributes);
        $user->save();

        return $user->fresh();
    }
}
