<?php

namespace App\Modules\Auth\Contracts;

use Firebase\JWT\Key;

interface JwksProvider
{
    /**
     * Returns the key set at the given JWKS URL, keyed by 'kid', as
     * Firebase\JWT\Key instances ready to pass to JWT::decode(). Fetching
     * and caching are implementation details -- callers only need a
     * signature-verification-ready key set.
     *
     * @return array<string, Key>
     */
    public function keySet(string $jwksUrl): array;
}
