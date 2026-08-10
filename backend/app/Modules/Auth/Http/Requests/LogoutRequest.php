<?php

namespace App\Modules\Auth\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * The access token (Authorization header, via the api guard) identifies the
 * user; refreshToken identifies which device session to revoke -- the API
 * Specification doesn't show a body example for this endpoint, so this
 * mirrors POST /auth/refresh's documented { refreshToken } shape, the only
 * client-held artifact that identifies a specific device session.
 */
class LogoutRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'refreshToken' => ['required', 'string'],
        ];
    }
}
