<?php

return [

    /*
    |--------------------------------------------------------------------------
    | OAuth Sign-In Configuration
    |--------------------------------------------------------------------------
    |
    | Server-side verification of Google/Apple-issued ID tokens, per
    | System Architecture section 8 ("Google/Apple sign-in verified
    | server-side via provider public keys/tokeninfo endpoints, never
    | trusting client-asserted identity"). Client secrets never appear here
    | directly -- only env() references, injected from the deployment
    | platform's secret store per docs/12-deployment-guide.md, same pattern
    | as config/jwt.php.
    |
    */

    'google' => [
        // The mobile app's OAuth client ID -- the audience ('aud' claim)
        // every Google-issued ID token must match.
        'client_id' => env('GOOGLE_OAUTH_CLIENT_ID'),

        'jwks_url' => env('GOOGLE_OAUTH_JWKS_URL', 'https://www.googleapis.com/oauth2/v3/certs'),

        // Google issues tokens with either form of this claim depending on
        // library/version -- both are accepted as valid.
        'issuers' => ['https://accounts.google.com', 'accounts.google.com'],
    ],

    'apple' => [
        // The Services ID / bundle ID every Apple-issued ID token's 'aud'
        // claim must match.
        'client_id' => env('APPLE_OAUTH_CLIENT_ID'),

        'jwks_url' => env('APPLE_OAUTH_JWKS_URL', 'https://appleid.apple.com/auth/keys'),

        'issuers' => ['https://appleid.apple.com'],
    ],

    // How long a fetched JWKS key set is cached before being re-fetched.
    // Provider signing keys rotate infrequently; this avoids a network call
    // to the provider on every single OAuth sign-in.
    'jwks_cache_ttl_seconds' => (int) env('OAUTH_JWKS_CACHE_TTL_SECONDS', 3600),

];
