<?php

namespace App\Modules\Auth\Http\Requests;

use App\Modules\Auth\Enums\Platform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Shared by both POST /auth/oauth/google and POST /auth/oauth/apple -- the
 * documented body shape is identical for both (API Specification section 3):
 * { idToken, platform, deviceName }.
 */
class OAuthLoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'idToken' => ['required', 'string'],
            'platform' => ['required', Rule::enum(Platform::class)],
            'deviceName' => ['nullable', 'string', 'max:120'],
        ];
    }

    public function platform(): Platform
    {
        return Platform::from($this->string('platform')->toString());
    }

    public function deviceName(): ?string
    {
        return $this->string('deviceName')->toString() ?: null;
    }
}
