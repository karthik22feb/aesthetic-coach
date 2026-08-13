<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Covers every provider-token verification failure (bad signature, wrong
 * issuer, wrong audience, expired, malformed, missing required claims) with
 * one generic message and error code -- deliberately not distinguishing
 * which check failed, so a caller probing this endpoint can't use the
 * response to fingerprint provider key rotation, clock skew, or client-ID
 * configuration.
 */
class InvalidOAuthTokenException extends AppException
{
    public function __construct()
    {
        parent::__construct(
            errorCode: 'unauthenticated',
            message: 'The provided sign-in token is invalid or expired.',
            status: 401,
        );
    }
}
