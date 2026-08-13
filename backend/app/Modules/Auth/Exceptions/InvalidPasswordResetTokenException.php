<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Covers every reset-token failure mode (unknown, expired, already used --
 * a used token is deleted, so "already used" and "unknown" are the same
 * observable state) with one generic response, so a caller can't use this
 * endpoint to probe which specific failure occurred. Reuses the 'unauthenticated'
 * code already documented in the error taxonomy (API Specification section 4)
 * rather than inventing a new one -- the semantic (missing/invalid/expired
 * token) matches exactly.
 */
class InvalidPasswordResetTokenException extends AppException
{
    public function __construct()
    {
        parent::__construct(
            errorCode: 'unauthenticated',
            message: 'This password reset link is invalid or has expired.',
            status: 401,
        );
    }
}
