<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Deliberately identical whether the email doesn't exist or the password is
 * wrong, to prevent user enumeration -- see docs/features/authentication.md
 * Edge Cases and docs/api-examples/auth.md (POST /auth/login).
 */
class InvalidCredentialsException extends AppException
{
    public function __construct()
    {
        parent::__construct(
            errorCode: 'unauthenticated',
            message: 'The provided credentials are incorrect.',
            status: 401,
        );
    }
}
