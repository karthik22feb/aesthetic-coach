<?php

namespace App\Modules\Auth\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Deliberately does NOT validate `exists:users,email` -- that would leak
 * account existence via a 422 the instant an unregistered email is
 * submitted, defeating the anti-enumeration response this endpoint is
 * required to give (docs/features/authentication.md Edge Cases: "generic
 * 'if this email exists, a reset link was sent' response"). Only format is
 * validated here; existence is checked silently in AuthService::forgotPassword().
 */
class ForgotPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:190'],
        ];
    }
}
