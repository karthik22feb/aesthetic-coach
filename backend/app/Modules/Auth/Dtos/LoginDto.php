<?php

namespace App\Modules\Auth\Dtos;

use App\Modules\Auth\Enums\Platform;

final readonly class LoginDto
{
    public function __construct(
        public string $email,
        public string $password,
        public Platform $platform,
        public ?string $deviceName,
    ) {}
}
