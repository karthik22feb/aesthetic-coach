<?php

namespace App\Modules\Auth\Events;

use App\Modules\Auth\Models\User;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Dispatched by AuthService::register(). No listeners are wired yet --
 * SendVerificationEmail (FR-104) and InitializeDefaultHabits are deferred to
 * their own future sessions (docs/07-backend-architecture.md section 5).
 */
class UserRegistered
{
    use Dispatchable;

    public function __construct(public readonly User $user) {}
}
