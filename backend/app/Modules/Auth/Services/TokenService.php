<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\User;
use Carbon\CarbonImmutable;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;
use stdClass;
use UnexpectedValueException;

/**
 * Issues and validates the two halves of the auth session per ADR-0005:
 * short-lived stateless JWT access tokens (RS256) and opaque, server-side-hashed,
 * rotating refresh tokens with a family_id rotation-chain (BR-3, BR-4).
 */
class TokenService
{
    /**
     * $deviceId is embedded as the 'did' claim so an authenticated request
     * can be traced back to the device it came from (used by
     * GET /auth/sessions to compute isCurrent -- see
     * App\Modules\Auth\AuthServiceProvider). Not documented as part of the
     * external API contract because it isn't one: the claim is internal
     * token plumbing, never inspected by the client.
     */
    public function issueAccessToken(User $user, ?int $deviceId = null): string
    {
        $now = CarbonImmutable::now();

        $payload = array_filter([
            'iss' => config('jwt.issuer'),
            'sub' => (string) $user->id,
            'did' => $deviceId,
            'iat' => $now->timestamp,
            'exp' => $now->addMinutes(config('jwt.access_ttl_minutes'))->timestamp,
        ], fn ($value) => $value !== null);

        return JWT::encode($payload, $this->privateKey(), config('jwt.algo'));
    }

    /**
     * @throws ExpiredException
     * @throws UnexpectedValueException
     */
    public function validateAccessToken(string $token): stdClass
    {
        // A static property on the library's JWT class, not per-instance state
        // -- scoped to this single decode call, safe within one request.
        JWT::$leeway = config('jwt.leeway_seconds');

        $payload = JWT::decode($token, new Key($this->publicKey(), config('jwt.algo')));

        if (! isset($payload->iss) || $payload->iss !== config('jwt.issuer')) {
            throw new UnexpectedValueException('Unexpected token issuer.');
        }

        return $payload;
    }

    public function accessTokenTtlSeconds(): int
    {
        return config('jwt.access_ttl_minutes') * 60;
    }

    /**
     * Issues a new refresh token for the given user/device. Omitting
     * $familyId starts a new rotation family (register/login); passing the
     * previous token's family_id continues it (refresh rotation) -- see
     * AuthService::refresh(). Returns the plaintext token (returned to the
     * client once, never stored) alongside the persisted record.
     *
     * @return array{token: string, model: AuthRefreshToken}
     */
    public function issueRefreshToken(User $user, Device $device, ?string $familyId = null): array
    {
        $plainToken = Str::random(64);

        $model = AuthRefreshToken::create([
            'user_id' => $user->id,
            'device_id' => $device->id,
            'token_hash' => hash('sha256', $plainToken),
            'family_id' => $familyId ?? (string) Str::uuid(),
            'expires_at' => CarbonImmutable::now()->addDays(config('jwt.refresh_ttl_days')),
        ]);

        return ['token' => $plainToken, 'model' => $model];
    }

    public function revoke(AuthRefreshToken $token): void
    {
        $token->update(['revoked_at' => CarbonImmutable::now()]);
    }

    /**
     * Revokes every still-active token in a rotation family -- used when
     * reuse of an already-rotated token is detected (BR-3), forcing every
     * device on that family to re-authenticate. Callers are expected to
     * already be inside a transaction with the relevant rows locked (see
     * AuthService::refresh()).
     *
     * @return Collection<int, AuthRefreshToken> the tokens that were revoked
     */
    public function revokeFamily(string $familyId): Collection
    {
        $tokens = AuthRefreshToken::where('family_id', $familyId)
            ->whereNull('revoked_at')
            ->lockForUpdate()
            ->get();

        $now = CarbonImmutable::now();

        foreach ($tokens as $token) {
            $token->update(['revoked_at' => $now]);
        }

        return $tokens;
    }

    protected function privateKey(): string
    {
        return config('jwt.private_key') ?: file_get_contents(config('jwt.private_key_path'));
    }

    protected function publicKey(): string
    {
        return config('jwt.public_key') ?: file_get_contents(config('jwt.public_key_path'));
    }
}
