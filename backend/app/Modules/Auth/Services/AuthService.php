<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Dtos\LoginDto;
use App\Modules\Auth\Dtos\RegisterDto;
use App\Modules\Auth\Enums\Platform;
use App\Modules\Auth\Events\SessionRevoked;
use App\Modules\Auth\Events\UserRegistered;
use App\Modules\Auth\Exceptions\InvalidCredentialsException;
use App\Modules\Auth\Exceptions\InvalidRefreshTokenException;
use App\Modules\Auth\Exceptions\SessionRevokedException;
use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    public function __construct(
        protected TokenService $tokenService,
    ) {}

    /**
     * @return array{user: User, accessToken: string, refreshToken: string, expiresIn: int}
     */
    public function register(RegisterDto $dto): array
    {
        $user = User::create([
            'name' => $dto->name,
            'email' => $dto->email,
            'password_hash' => $dto->password,
        ]);

        $device = $this->registerDevice($user, $dto->platform, $dto->deviceName);

        UserRegistered::dispatch($user);

        return $this->issueSession($user, $device);
    }

    /**
     * @return array{user: User, accessToken: string, refreshToken: string, expiresIn: int}
     *
     * @throws InvalidCredentialsException
     */
    public function login(LoginDto $dto): array
    {
        $user = User::where('email', $dto->email)->first();

        if (! $user || ! Hash::check($dto->password, $user->password_hash)) {
            throw new InvalidCredentialsException;
        }

        $device = $this->registerDevice($user, $dto->platform, $dto->deviceName);

        return $this->issueSession($user, $device);
    }

    /**
     * Rotates a refresh token per BR-3/BR-4: the presented token is looked
     * up and row-locked inside a transaction, so two requests racing on the
     * same token can never both succeed (the second sees the first's
     * revocation and is treated as a reuse attempt -- see below). On
     * success, the old token is revoked and a new one is issued in the same
     * rotation family (family_id carried forward, not reset).
     *
     * Reuse detection (BR-3): a token found already revoked_at means it was
     * already rotated away by an earlier, successful refresh -- submitting
     * it again is either a stolen/replayed token or a client retrying after
     * losing a race with itself. Either way, the whole family is revoked
     * and every device on it must re-authenticate; the server cannot safely
     * distinguish "malicious replay" from "lost race" and treats both the
     * same, per the documented Gherkin scenario in
     * docs/features/authentication.md.
     *
     * @return array{accessToken: string, refreshToken: string, expiresIn: int}
     *
     * @throws InvalidRefreshTokenException
     * @throws SessionRevokedException
     */
    public function refresh(string $plainRefreshToken): array
    {
        $tokenHash = hash('sha256', $plainRefreshToken);

        // The transaction closure returns a status instead of throwing
        // directly: DB::transaction() rolls back ALL writes made inside it
        // when the closure throws, which would silently undo the family
        // revocation below the moment SessionRevokedException propagated.
        // Throwing only after the transaction has committed keeps the
        // revocation durable.
        //
        // Retries (3 attempts): two requests replaying two *different*
        // already-revoked tokens from the same family can lock rows in
        // opposite orders (A locks token X then wants Y; B locks Y then
        // wants X), which MySQL's deadlock detector resolves by aborting
        // one transaction. Laravel automatically retries on a detected
        // deadlock when given an attempt count.
        $outcome = DB::transaction(function () use ($tokenHash) {
            $token = AuthRefreshToken::where('token_hash', $tokenHash)
                ->lockForUpdate()
                ->first();

            if ($token === null) {
                return ['status' => 'not_found'];
            }

            if ($token->revoked_at !== null) {
                $revoked = $this->tokenService->revokeFamily($token->family_id);

                return ['status' => 'reused', 'revoked' => $revoked];
            }

            if ($token->expires_at->isPast()) {
                return ['status' => 'expired'];
            }

            $user = $token->user;
            $device = $token->device;

            $this->tokenService->revoke($token);

            $rotated = $this->tokenService->issueRefreshToken($user, $device, $token->family_id);

            return [
                'status' => 'ok',
                'accessToken' => $this->tokenService->issueAccessToken($user),
                'refreshToken' => $rotated['token'],
                'expiresIn' => $this->tokenService->accessTokenTtlSeconds(),
            ];
        }, 3);

        if ($outcome['status'] === 'reused') {
            foreach ($outcome['revoked'] as $revokedToken) {
                SessionRevoked::dispatch($revokedToken);
            }

            throw new SessionRevokedException;
        }

        return match ($outcome['status']) {
            'not_found' => throw InvalidRefreshTokenException::notFound(),
            'expired' => throw InvalidRefreshTokenException::expired(),
            'ok' => [
                'accessToken' => $outcome['accessToken'],
                'refreshToken' => $outcome['refreshToken'],
                'expiresIn' => $outcome['expiresIn'],
            ],
        };
    }

    /**
     * Revokes the refresh token identifying the current device session.
     * Silently succeeds if the token is unknown/already revoked -- logout is
     * idempotent from the client's point of view.
     */
    public function logout(User $user, string $refreshToken): void
    {
        $token = AuthRefreshToken::query()
            ->where('user_id', $user->id)
            ->where('token_hash', hash('sha256', $refreshToken))
            ->whereNull('revoked_at')
            ->first();

        if ($token === null) {
            return;
        }

        $this->tokenService->revoke($token);

        SessionRevoked::dispatch($token);
    }

    /**
     * Creates the devices row backing this session's refresh token per
     * Database Design section 3.1 -- see the register/login endpoint docs
     * for why platform/deviceName are required inputs.
     */
    protected function registerDevice(User $user, Platform $platform, ?string $deviceName): Device
    {
        return Device::create([
            'user_id' => $user->id,
            'platform' => $platform,
            'device_name' => $deviceName ?: ucfirst($platform->value).' device',
            'last_active_at' => now(),
        ]);
    }

    /**
     * @return array{user: User, accessToken: string, refreshToken: string, expiresIn: int}
     */
    protected function issueSession(User $user, Device $device): array
    {
        $refresh = $this->tokenService->issueRefreshToken($user, $device);

        return [
            'user' => $user,
            'accessToken' => $this->tokenService->issueAccessToken($user),
            'refreshToken' => $refresh['token'],
            'expiresIn' => $this->tokenService->accessTokenTtlSeconds(),
        ];
    }
}
