<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Contracts\JwksProvider;
use App\Modules\Auth\Enums\OAuthProvider;

class GoogleIdTokenVerifier extends AbstractOAuthIdTokenVerifier
{
    public function __construct(JwksProvider $jwks)
    {
        parent::__construct(
            jwks: $jwks,
            jwksUrl: config('oauth.google.jwks_url'),
            issuers: config('oauth.google.issuers'),
            audience: config('oauth.google.client_id'),
            provider: OAuthProvider::Google,
        );
    }
}
