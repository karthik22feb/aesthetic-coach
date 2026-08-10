<?php

namespace App\Modules\Auth\Http\Requests;

use App\Modules\Auth\Dtos\LoginDto;
use App\Modules\Auth\Enums\Platform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:190'],
            'password' => ['required', 'string'],
            'platform' => ['required', Rule::enum(Platform::class)],
            'deviceName' => ['nullable', 'string', 'max:120'],
        ];
    }

    public function toDto(): LoginDto
    {
        return new LoginDto(
            email: $this->string('email')->toString(),
            password: $this->string('password')->toString(),
            platform: Platform::from($this->string('platform')->toString()),
            deviceName: $this->string('deviceName')->toString() ?: null,
        );
    }
}
