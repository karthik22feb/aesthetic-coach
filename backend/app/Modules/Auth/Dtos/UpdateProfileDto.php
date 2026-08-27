<?php

namespace App\Modules\Auth\Dtos;

/**
 * PATCH /me is a partial update -- unlike the other DTOs in this module,
 * a fixed set of named properties can't distinguish "field omitted" from
 * "field explicitly set to null" for the nullable columns (sex,
 * dateOfBirth, heightCm, dietaryRestrictions). $attributes therefore only
 * ever contains the keys the client actually sent (see
 * UpdateProfileRequest::toDto()), already mapped to their `users` column
 * names.
 */
final readonly class UpdateProfileDto
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function __construct(public array $attributes) {}
}
