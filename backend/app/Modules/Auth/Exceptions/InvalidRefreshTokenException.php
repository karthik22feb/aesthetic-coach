<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Covers a refresh token that is unknown (never issued) or has naturally
 * expired (past its 30-day sliding window, BR-4) -- distinct from
 * SessionRevokedException, which is specifically for detected reuse of an
 * already-rotated token (BR-3).
 */
class InvalidRefreshTokenException extends AppException
{
    public static function notFound(): self
    {
        return new self('The refresh token is invalid.');
    }

    public static function expired(): self
    {
        return new self('Your session has expired. Please log in again.');
    }

    private function __construct(string $message)
    {
        parent::__construct('unauthenticated', $message, 401);
    }
}
