<?php

namespace App\Modules\Auth\Contracts;

use App\Modules\Auth\Exceptions\InvalidOAuthTokenException;
use App\Modules\Auth\Support\OAuthClaims;

interface OAuthTokenVerifier
{
    /**
     * Verifies a provider-issued ID token server-side (signature against the
     * provider's published JWKS, issuer, audience, expiration, required
     * claims present) and returns only the verified identity claims. Never
     * trusts any claim before every check has passed.
     *
     * @throws InvalidOAuthTokenException on any verification failure --
     *                                    deliberately generic (never reveals which specific check
     *                                    failed) to avoid giving an attacker a verification oracle.
     */
    public function verify(string $idToken): OAuthClaims;
}
