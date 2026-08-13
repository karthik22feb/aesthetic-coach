<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Contracts\OAuthTokenVerifier;
use App\Modules\Auth\Enums\OAuthProvider;
use Illuminate\Contracts\Container\Container;

/**
 * Resolves the correct verifier for a given provider through the container
 * (rather than a hard-coded match/switch instantiating them directly), so
 * tests can swap in a fake verifier for GoogleIdTokenVerifier::class or
 * AppleIdTokenVerifier::class without this factory needing to know.
 */
class OAuthVerifierFactory
{
    public function __construct(protected Container $container) {}

    public function for(OAuthProvider $provider): OAuthTokenVerifier
    {
        return match ($provider) {
            OAuthProvider::Google => $this->container->make(GoogleIdTokenVerifier::class),
            OAuthProvider::Apple => $this->container->make(AppleIdTokenVerifier::class),
        };
    }
}
