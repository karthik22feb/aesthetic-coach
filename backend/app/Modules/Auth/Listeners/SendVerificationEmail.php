<?php

namespace App\Modules\Auth\Listeners;

use App\Modules\Auth\Events\UserRegistered;
use App\Modules\Auth\Services\AuthService;

/**
 * Wires FR-101's acceptance criteria ("account is created and verification
 * email sent") -- previously deferred, per UserRegistered's own docblock,
 * to this session (FR-104).
 */
class SendVerificationEmail
{
    public function __construct(protected AuthService $authService) {}

    public function handle(UserRegistered $event): void
    {
        $this->authService->sendVerificationEmail($event->user);
    }
}
