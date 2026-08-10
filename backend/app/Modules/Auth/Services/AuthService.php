<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Dtos\LoginDto;
use App\Modules\Auth\Dtos\RegisterDto;
use App\Modules\Auth\Enums\Platform;
use App\Modules\Auth\Events\SessionRevoked;
use App\Modules\Auth\Events\UserRegistered;
use App\Modules\Auth\Exceptions\InvalidCredentialsException;
use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\User;
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
