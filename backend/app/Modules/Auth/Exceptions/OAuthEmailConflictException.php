<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Raised when a provider ID token's email matches an existing user's email,
 * but the provider did not assert the email as verified -- see
 * docs/features/authentication.md Edge Cases ("account is linked (matched
 * by verified email)"). Auto-linking on an unverified provider claim would
 * let anyone who controls an OAuth account with a matching-but-unverified
 * email address take over an existing password-based account, so this is
 * refused rather than silently linked or silently duplicated (the latter is
 * also impossible: users.email is UNIQUE).
 */
class OAuthEmailConflictException extends AppException
{
    public function __construct()
    {
        parent::__construct(
            errorCode: 'conflict',
            message: 'An account already exists with this email. Sign in with your password, or verify this email with the provider first.',
            status: 409,
        );
    }
}
