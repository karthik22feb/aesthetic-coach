<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Contracts\JwksProvider;
use Firebase\JWT\JWK;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

/**
 * Fetches a provider's published JWKS over HTTP and caches the raw (plain
 * array, Redis-serializable) response -- provider signing keys rotate
 * infrequently, so this avoids a network round-trip to Google/Apple on
 * every single OAuth sign-in. Key::class objects are re-derived from the
 * cached raw JSON on every call (cheap, no I/O), rather than caching the
 * parsed Key objects themselves, since OpenSSL key material doesn't survive
 * a Redis round-trip reliably.
 */
class HttpJwksProvider implements JwksProvider
{
    public function keySet(string $jwksUrl): array
    {
        $ttl = (int) config('oauth.jwks_cache_ttl_seconds');
        $cacheKey = 'oauth:jwks:'.md5($jwksUrl);

        $raw = Cache::remember($cacheKey, $ttl, function () use ($jwksUrl) {
            return Http::timeout(5)->get($jwksUrl)->throw()->json();
        });

        return JWK::parseKeySet($raw);
    }
}
