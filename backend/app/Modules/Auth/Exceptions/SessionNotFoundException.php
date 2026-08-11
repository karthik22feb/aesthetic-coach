<?php

namespace App\Modules\Auth\Exceptions;

use App\Shared\Support\AppException;

/**
 * Covers both a genuinely nonexistent device ID and a device ID that
 * belongs to another user -- collapsed to the same 404, per
 * docs/05-api-specification.md section 4 ("Resource doesn't exist or
 * isn't owned by the caller"), so a caller can never distinguish
 * "not yours" from "doesn't exist" (IDOR/enumeration protection).
 */
class SessionNotFoundException extends AppException
{
    public function __construct()
    {
        parent::__construct(
            errorCode: 'not_found',
            message: 'Session not found.',
            status: 404,
        );
    }
}
