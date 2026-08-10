<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Thrown when a refresh token that was already rotated away (revoked_at
 * set) is submitted again -- BR-3 reuse detection. The caller is
 * responsible for revoking the whole token family before throwing this;
 * see AuthService::refresh().
 */
class SessionRevokedException extends AppException
{
    public function __construct()
    {
        parent::__construct(
            errorCode: 'session_revoked',
            message: 'This session has been revoked. Please log in again.',
            status: 401,
        );
    }
}
