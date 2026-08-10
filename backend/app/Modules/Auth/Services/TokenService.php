<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\User;
use Carbon\CarbonImmutable;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Str;
use stdClass;
use UnexpectedValueException;

/**
 * Issues and validates the two halves of the auth session per ADR-0005:
 * short-lived stateless JWT access tokens (RS256) and opaque, server-side-hashed,
 * rotating refresh tokens with a family_id rotation-chain (BR-3, BR-4).
 *
 * Refresh-token rotation itself (replacing a used token with a new one in the
 * same family, and revoking the family on reuse) is not implemented yet -- this
 * class only prepares the primitives (family_id assignment, single-token revoke)
 * that the future /auth/refresh endpoint will build on.
 */
class TokenService
{
    public function issueAccessToken(User $user): string
    {
        $now = CarbonImmutable::now();

        $payload = [
            'iss' => config('jwt.issuer'),
            'sub' => (string) $user->id,
            'iat' => $now->timestamp,
            'exp' => $now->addMinutes(config('jwt.access_ttl_minutes'))->timestamp,
        ];

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
     * Issues a new refresh token for the given user/device, starting a new
     * rotation family. Returns the plaintext token (returned to the client
     * once, never stored) alongside the persisted record.
     *
     * @return array{token: string, model: AuthRefreshToken}
     */
    public function issueRefreshToken(User $user, Device $device): array
    {
        $plainToken = Str::random(64);

        $model = AuthRefreshToken::create([
            'user_id' => $user->id,
            'device_id' => $device->id,
            'token_hash' => hash('sha256', $plainToken),
            'family_id' => (string) Str::uuid(),
            'expires_at' => CarbonImmutable::now()->addDays(config('jwt.refresh_ttl_days')),
        ]);

        return ['token' => $plainToken, 'model' => $model];
    }

    public function revoke(AuthRefreshToken $token): void
    {
        $token->update(['revoked_at' => CarbonImmutable::now()]);
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
