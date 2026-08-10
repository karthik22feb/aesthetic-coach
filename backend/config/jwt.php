<?php

return [

    /*
    |--------------------------------------------------------------------------
    | JWT Access Token Configuration
    |--------------------------------------------------------------------------
    |
    | Custom JWT + rotating refresh token auth, per ADR-0005 (docs/adr/0005-jwt-refresh-token-auth.md).
    | Access tokens are RS256-signed and stateless (BR-4); refresh tokens are
    | opaque and stored hashed -- see App\Modules\Auth\Services\TokenService.
    |
    | Signing keys: JWT_PRIVATE_KEY / JWT_PUBLIC_KEY hold PEM content directly
    | (the production pattern, injected from a managed secret store per
    | docs/12-deployment-guide.md section 7). If unset, falls back to the file
    | paths below for local development.
    |
    */

    'algo' => 'RS256',

    'access_ttl_minutes' => (int) env('JWT_ACCESS_TTL_MINUTES', 15),

    'refresh_ttl_days' => (int) env('JWT_REFRESH_TTL_DAYS', 30),

    'private_key' => env('JWT_PRIVATE_KEY'),

    'public_key' => env('JWT_PUBLIC_KEY'),

    'private_key_path' => env('JWT_PRIVATE_KEY_PATH', storage_path('app/jwt/private.pem')),

    'public_key_path' => env('JWT_PUBLIC_KEY_PATH', storage_path('app/jwt/public.pem')),

    // The expected 'iss' claim on every access token -- validated on decode,
    // not just asserted at issuance.
    'issuer' => env('JWT_ISSUER', env('APP_NAME', 'Laravel')),

    // Small, standard tolerance for clock drift between app instances in the
    // horizontally-scaled tier (docs/03-system-architecture.md section 7).
    // Does not change the documented 15-minute access token TTL (BR-4) --
    // only smooths the exp/iat boundary check.
    'leeway_seconds' => (int) env('JWT_LEEWAY_SECONDS', 5),

];
