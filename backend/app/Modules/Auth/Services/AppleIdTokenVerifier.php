<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Contracts\JwksProvider;
use App\Modules\Auth\Enums\OAuthProvider;

class AppleIdTokenVerifier extends AbstractOAuthIdTokenVerifier
{
    public function __construct(JwksProvider $jwks)
    {
        parent::__construct(
            jwks: $jwks,
            jwksUrl: config('oauth.apple.jwks_url'),
            issuers: config('oauth.apple.issuers'),
            audience: config('oauth.apple.client_id'),
            provider: OAuthProvider::Apple,
        );
    }
}
