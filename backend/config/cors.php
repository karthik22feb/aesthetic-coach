<?php

/*
|--------------------------------------------------------------------------
| Cross-Origin Resource Sharing (CORS) Configuration
|--------------------------------------------------------------------------
|
| The mobile app doesn't use CORS at all (native HTTP, not a browser), but
| any future web client/admin panel must be explicitly allow-listed here --
| never a wildcard -- per docs/14-production-hardening.md section 5.
|
| CORS_ALLOWED_ORIGINS is a comma-separated list of exact origins, e.g.
| "https://admin.aestheticcoach.app,https://app.aestheticcoach.app". Empty
| by default: no browser-based client exists yet, so the safe default is to
| allow none rather than guess a domain.
|
*/

return [

    'paths' => ['api/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env('CORS_ALLOWED_ORIGINS', ''))
    ))),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // No cookie-based session is ever used for this API (stateless JWT bearer
    // tokens, per ADR-0005) -- credentialed CORS requests are never needed.
    'supports_credentials' => false,

];
