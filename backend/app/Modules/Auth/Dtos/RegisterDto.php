<?php

namespace App\Modules\Auth\Dtos;

use App\Modules\Auth\Enums\Platform;

final readonly class RegisterDto
{
    public function __construct(
        public string $name,
        public string $email,
        public string $password,
        public Platform $platform,
        public ?string $deviceName,
    ) {}
}
