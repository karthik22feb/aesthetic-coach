<?php

namespace App\Modules\Auth\Events;

use App\Modules\Auth\Models\AuthRefreshToken;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Dispatched by TokenService/AuthService on logout (and, in a future session,
 * on refresh-token reuse detection). No listeners are wired yet --
 * NotifyUserOfNewDeviceOrRevocation is deferred (Notifications module,
 * docs/07-backend-architecture.md section 5).
 */
class SessionRevoked
{
    use Dispatchable;

    public function __construct(public readonly AuthRefreshToken $refreshToken) {}
}
