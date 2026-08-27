<?php

namespace App\Modules\Auth\Http\Resources;

use App\Modules\Auth\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The full `GET/PATCH /me` shape, per
 * docs/api-examples/users-profile.md -- deliberately separate from
 * [UserResource], which stays a narrow (id/name/email/emailVerified)
 * shape embedded in auth responses (register/login/refresh). Changing
 * UserResource itself to add these fields would silently change every
 * existing auth endpoint's documented response shape.
 *
 * @mixin User
 */
class ProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'emailVerified' => $this->email_verified_at !== null,
            'timezone' => $this->timezone,
            'unitPreference' => $this->unit_preference->value,
            'dateOfBirth' => $this->date_of_birth?->toDateString(),
            'sex' => $this->sex?->value,
            'heightCm' => $this->height_cm !== null ? (float) $this->height_cm : null,
            'dietaryRestrictions' => $this->dietary_restrictions ?? [],
        ];
    }
}
