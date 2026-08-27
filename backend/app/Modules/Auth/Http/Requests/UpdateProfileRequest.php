<?php

namespace App\Modules\Auth\Http\Requests;

use App\Modules\Auth\Dtos\UpdateProfileDto;
use App\Modules\Auth\Enums\Sex;
use App\Modules\Auth\Enums\UnitPreference;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

/**
 * All fields are `sometimes` -- PATCH semantics, per
 * docs/features/profile.md ("view and edit name, timezone, unit
 * preference, DOB, sex, height, dietary restrictions"). Validation
 * mirrors onboarding's profile-basics step exactly, per that doc's own
 * "same as onboarding" cross-reference:
 * docs/features/onboarding.md#validation-rules (timezone: valid IANA;
 * DOB: optional, must be 18+) and docs/features/profile.md's own
 * height range (50-250cm).
 */
class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'filled', 'string', 'max:120'],
            'timezone' => ['sometimes', 'string', 'timezone:all'],
            'unitPreference' => ['sometimes', Rule::enum(UnitPreference::class)],
            'dateOfBirth' => [
                'sometimes',
                'nullable',
                'date',
                'before_or_equal:'.Carbon::now()->subYears(18)->toDateString(),
            ],
            'sex' => ['sometimes', 'nullable', Rule::enum(Sex::class)],
            'heightCm' => ['sometimes', 'nullable', 'numeric', 'between:50,250'],
            'dietaryRestrictions' => ['sometimes', 'nullable', 'array'],
            'dietaryRestrictions.*' => ['string', 'max:50'],
        ];
    }

    public function toDto(): UpdateProfileDto
    {
        $columnByField = [
            'name' => 'name',
            'timezone' => 'timezone',
            'unitPreference' => 'unit_preference',
            'dateOfBirth' => 'date_of_birth',
            'sex' => 'sex',
            'heightCm' => 'height_cm',
            'dietaryRestrictions' => 'dietary_restrictions',
        ];

        $attributes = [];
        foreach ($columnByField as $field => $column) {
            if ($this->has($field)) {
                $attributes[$column] = $this->input($field);
            }
        }

        return new UpdateProfileDto($attributes);
    }
}
