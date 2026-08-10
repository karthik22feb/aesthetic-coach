<?php

namespace App\Modules\Auth\Http\Requests;

use App\Modules\Auth\Dtos\RegisterDto;
use App\Modules\Auth\Enums\Platform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Validation per docs/features/authentication.md Validation Rules and BR-1
 * (password policy: 10+ chars, at least 1 letter and 1 number).
 */
class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'string', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'min:10', 'regex:/[A-Za-z]/', 'regex:/[0-9]/'],
            'platform' => ['required', Rule::enum(Platform::class)],
            'deviceName' => ['nullable', 'string', 'max:120'],
        ];
    }

    public function toDto(): RegisterDto
    {
        return new RegisterDto(
            name: $this->string('name')->toString(),
            email: $this->string('email')->toString(),
            password: $this->string('password')->toString(),
            platform: Platform::from($this->string('platform')->toString()),
            deviceName: $this->string('deviceName')->toString() ?: null,
        );
    }
}
