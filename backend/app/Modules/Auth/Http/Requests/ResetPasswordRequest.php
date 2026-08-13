<?php

namespace App\Modules\Auth\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Password rule is identical to RegisterRequest's (BR-1: 10+ chars, at
 * least 1 letter and 1 number) -- a reset must not let a user land on a
 * weaker password than registration would have allowed.
 */
class ResetPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'token' => ['required', 'string'],
            'password' => ['required', 'string', 'min:10', 'regex:/[A-Za-z]/', 'regex:/[0-9]/'],
        ];
    }
}
