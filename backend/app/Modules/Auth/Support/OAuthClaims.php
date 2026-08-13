<?php

namespace App\Modules\Auth\Support;

use App\Modules\Auth\Enums\OAuthProvider;

/**
 * The subset of a verified provider ID token's claims this module actually
 * needs, extracted only after signature/issuer/audience/expiration have all
 * passed -- never constructed from unverified client input.
 */
final readonly class OAuthClaims
{
    public function __construct(
        public OAuthProvider $provider,
        public string $providerUserId,
        public string $email,
        public bool $emailVerified,
        // Google typically includes a 'name' claim (when the 'profile'
        // scope was granted); Apple's ID token never includes one at all
        // (Apple only returns given/family name once, out-of-band, on the
        // client's very first authorization -- not part of this endpoint's
        // documented { idToken, platform, deviceName } request). Null means
        // the caller falls back to a derived default, the same pattern
        // already used for an omitted deviceName.
        public ?string $name = null,
    ) {}
}
