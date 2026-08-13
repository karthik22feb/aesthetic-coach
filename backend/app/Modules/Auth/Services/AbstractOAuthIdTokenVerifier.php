<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Contracts\JwksProvider;
use App\Modules\Auth\Contracts\OAuthTokenVerifier;
use App\Modules\Auth\Enums\OAuthProvider;
use App\Modules\Auth\Exceptions\InvalidOAuthTokenException;
use App\Modules\Auth\Support\OAuthClaims;
use Firebase\JWT\JWT;
use Throwable;

/**
 * Shared RS256 ID-token verification for both providers: signature (against
 * the provider's published JWKS), issuer, audience, expiration (checked by
 * JWT::decode() itself), and presence of the claims this module needs.
 * Google and Apple differ only in their JWKS URL, issuer string(s), and how
 * they encode 'email_verified' (Apple sends it as the string "true"/"false"
 * rather than a JSON boolean) -- see the two concrete subclasses.
 */
abstract class AbstractOAuthIdTokenVerifier implements OAuthTokenVerifier
{
    public function __construct(
        protected JwksProvider $jwks,
        protected string $jwksUrl,
        protected array $issuers,
        protected ?string $audience,
        protected OAuthProvider $provider,
    ) {}

    public function verify(string $idToken): OAuthClaims
    {
        // Every failure path -- bad signature, wrong issuer, wrong audience,
        // expired, malformed, missing claims -- collapses to the same
        // exception. Distinguishing them in the response would hand an
        // attacker a verification oracle (e.g. confirming a token's
        // signature is valid but the audience is wrong leaks the fact that
        // the token was genuinely provider-issued for a *different* client).
        try {
            if ($this->audience === null) {
                throw new InvalidOAuthTokenException;
            }

            $keySet = $this->jwks->keySet($this->jwksUrl);

            // Same small tolerance already used for this app's own JWTs
            // (config('jwt.leeway_seconds')) -- smooths clock drift between
            // this server and the provider's, doesn't change the token's
            // actual issued lifetime.
            JWT::$leeway = (int) config('jwt.leeway_seconds');

            $payload = JWT::decode($idToken, $keySet);

            if (! isset($payload->iss) || ! in_array($payload->iss, $this->issuers, true)) {
                throw new InvalidOAuthTokenException;
            }

            $aud = $payload->aud ?? null;
            $audienceMatches = is_array($aud)
                ? in_array($this->audience, $aud, true)
                : $aud === $this->audience;

            if (! $audienceMatches) {
                throw new InvalidOAuthTokenException;
            }

            if (! isset($payload->sub) || ! isset($payload->email)) {
                throw new InvalidOAuthTokenException;
            }

            return new OAuthClaims(
                provider: $this->provider,
                providerUserId: (string) $payload->sub,
                email: (string) $payload->email,
                emailVerified: $this->normalizeEmailVerified($payload->email_verified ?? null),
                name: isset($payload->name) ? (string) $payload->name : null,
            );
        } catch (InvalidOAuthTokenException $e) {
            throw $e;
        } catch (Throwable) {
            throw new InvalidOAuthTokenException;
        }
    }

    protected function normalizeEmailVerified(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        if (is_string($value)) {
            return $value === 'true';
        }

        return false;
    }
}
