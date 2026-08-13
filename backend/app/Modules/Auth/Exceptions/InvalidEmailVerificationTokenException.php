<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Covers every verification-token failure mode (unknown, expired, already
 * used -- a used token is deleted) with one generic response. Mirrors
 * InvalidPasswordResetTokenException's reasoning exactly.
 */
class InvalidEmailVerificationTokenException extends AppException
{
    public function __construct()
    {
        parent::__construct(
            errorCode: 'unauthenticated',
            message: 'This verification link is invalid or has expired.',
            status: 401,
        );
    }
}
