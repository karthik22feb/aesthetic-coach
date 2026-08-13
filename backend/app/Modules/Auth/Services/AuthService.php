<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Dtos\LoginDto;
use App\Modules\Auth\Dtos\RegisterDto;
use App\Modules\Auth\Enums\OAuthProvider;
use App\Modules\Auth\Enums\Platform;
use App\Modules\Auth\Events\SessionRevoked;
use App\Modules\Auth\Events\UserRegistered;
use App\Modules\Auth\Exceptions\InvalidCredentialsException;
use App\Modules\Auth\Exceptions\InvalidEmailVerificationTokenException;
use App\Modules\Auth\Exceptions\InvalidOAuthTokenException;
use App\Modules\Auth\Exceptions\InvalidPasswordResetTokenException;
use App\Modules\Auth\Exceptions\InvalidRefreshTokenException;
use App\Modules\Auth\Exceptions\OAuthEmailConflictException;
use App\Modules\Auth\Exceptions\SessionNotFoundException;
use App\Modules\Auth\Exceptions\SessionRevokedException;
use App\Modules\Auth\Mail\EmailVerificationMail;
use App\Modules\Auth\Mail\PasswordResetMail;
use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\EmailVerificationToken;
use App\Modules\Auth\Models\OAuthIdentity;
use App\Modules\Auth\Models\PasswordResetToken;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Support\OAuthClaims;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AuthService
{
    /**
     * Email verification and password reset tokens share the same
     * lifetime (60 minutes) -- FR-105's acceptance criteria states this
     * explicitly for password reset; FR-104 (email verification) has no
     * documented token contract at all, so this session mirrors the
     * password-reset value for consistency rather than inventing a
     * different one (see ENGINEERING_DECISION_LOG.md).
     */
    protected const TOKEN_TTL_MINUTES = 60;

    public function __construct(
        protected TokenService $tokenService,
        protected OAuthVerifierFactory $oauthVerifiers,
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
                'accessToken' => $this->tokenService->issueAccessToken($user, $device->id),
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
     * Verifies a provider ID token server-side, resolves (or creates) the
     * corresponding user, and issues a normal session -- the same shape as
     * register()/login() (API Specification section 3: "Response shape
     * identical to register"). Never trusts any client-asserted identity;
     * every field used below comes from OAuthClaims, which only exists
     * after OAuthTokenVerifier has independently verified signature,
     * issuer, audience, and expiration.
     *
     * @return array{user: User, accessToken: string, refreshToken: string, expiresIn: int, created: bool}
     *
     * @throws InvalidOAuthTokenException
     * @throws OAuthEmailConflictException
     */
    public function oauthLogin(OAuthProvider $provider, string $idToken, Platform $platform, ?string $deviceName): array
    {
        $claims = $this->oauthVerifiers->for($provider)->verify($idToken);

        [$user, $created] = $this->resolveOAuthUser($provider, $claims);

        $device = $this->registerDevice($user, $platform, $deviceName);

        return [...$this->issueSession($user, $device), 'created' => $created];
    }

    /**
     * @return array{0: User, 1: bool} the resolved user and whether it was
     *                                 newly created by this call
     *
     * @throws OAuthEmailConflictException
     */
    protected function resolveOAuthUser(OAuthProvider $provider, OAuthClaims $claims): array
    {
        $identity = OAuthIdentity::where('provider', $provider)
            ->where('provider_user_id', $claims->providerUserId)
            ->first();

        if ($identity !== null) {
            return [$identity->user, false];
        }

        try {
            return DB::transaction(function () use ($provider, $claims) {
                // Per docs/features/authentication.md Edge Cases: a user who
                // signed up with email/password and later signs in via
                // Google/Apple using the same email is linked, not
                // duplicated (users.email is UNIQUE, so duplication is
                // impossible regardless) -- but only when the provider
                // itself asserts the email is verified. An unverified claim
                // is refused rather than linked, so control of an
                // unverified mailbox at the provider can't be used to take
                // over an existing password-based account.
                $user = User::where('email', $claims->email)->first();

                if ($user !== null) {
                    if (! $claims->emailVerified) {
                        throw new OAuthEmailConflictException;
                    }
                } else {
                    $user = User::create([
                        'name' => $claims->name ?? Str::before($claims->email, '@'),
                        'email' => $claims->email,
                        'password_hash' => null,
                    ]);

                    // email_verified_at is never client-settable (not in
                    // User's #[Fillable(...)] list) -- set directly here
                    // only because the provider, not the client, verified it.
                    if ($claims->emailVerified) {
                        $user->forceFill(['email_verified_at' => now()])->save();
                    }
                }

                OAuthIdentity::create([
                    'user_id' => $user->id,
                    'provider' => $provider,
                    'provider_user_id' => $claims->providerUserId,
                ]);

                return [$user, $user->wasRecentlyCreated];
            });
        } catch (QueryException $e) {
            if ((int) ($e->errorInfo[1] ?? 0) !== 1062) {
                throw $e;
            }

            // Lost a race to a concurrent sign-in for the same provider
            // identity (UNIQUE(provider, provider_user_id) in the
            // oauth_identities migration) -- the other request already
            // created it between our lookup above and this transaction.
            // Resolve normally instead of surfacing a raw 500.
            $identity = OAuthIdentity::where('provider', $provider)
                ->where('provider_user_id', $claims->providerUserId)
                ->firstOrFail();

            return [$identity->user, false];
        }
    }

    /**
     * Lists the user's active sessions/devices per FR-106: a device with at
     * least one refresh token that is neither revoked nor expired. Ordered
     * most-recently-active first, matching the documented example in
     * docs/api-examples/auth.md.
     *
     * @return Collection<int, Device>
     */
    public function listSessions(User $user): Collection
    {
        return Device::where('user_id', $user->id)
            ->whereHas('authRefreshTokens', function ($query) {
                $query->whereNull('revoked_at')->where('expires_at', '>', now());
            })
            ->orderByDesc('last_active_at')
            ->get();
    }

    /**
     * Revokes a specific device's active refresh token(s) per FR-106
     * ("revoke invalidates that device's refresh token immediately").
     * Ownership is checked at the query level (never trust the ID alone,
     * per docs/coding-standards.md) -- a device that exists but belongs to
     * another user is indistinguishable from one that doesn't exist at all,
     * both raising SessionNotFoundException (404), never 403, so a caller
     * can't use this endpoint to enumerate other users' device IDs.
     *
     * Idempotent: revoking a device with no active tokens (already revoked,
     * or never had one) is a silent no-op, consistent with DELETE semantics
     * and this module's existing logout() idempotency.
     *
     * Row-locked inside a transaction, same as refresh()/revokeFamily(): an
     * unlocked read-then-update here could race a concurrent refresh() on
     * the same device (that call rotates the token to a new row via its own
     * lockForUpdate transaction), letting the newly-rotated token silently
     * survive a revoke that should have killed the whole device session.
     *
     * @throws SessionNotFoundException
     */
    public function revokeSession(User $user, int $deviceId): void
    {
        $device = Device::where('user_id', $user->id)->where('id', $deviceId)->first();

        if ($device === null) {
            throw new SessionNotFoundException;
        }

        $tokens = DB::transaction(function () use ($device) {
            $tokens = AuthRefreshToken::where('device_id', $device->id)
                ->whereNull('revoked_at')
                ->lockForUpdate()
                ->get();

            foreach ($tokens as $token) {
                $this->tokenService->revoke($token);
            }

            return $tokens;
        }, 3);

        foreach ($tokens as $token) {
            SessionRevoked::dispatch($token);
        }
    }

    /**
     * Issues a password reset token and emails it, per FR-105 ("Reset link
     * expires in 60 minutes, single use"). Deliberately silent (no
     * exception, no signal of any kind) when the email doesn't match a
     * user -- the controller returns the same generic response either way,
     * per the documented anti-enumeration rule (Edge Cases: "generic 'if
     * this email exists, a reset link was sent' response").
     *
     * The mail is queued rather than sent synchronously specifically so
     * that a found vs. not-found email can't be distinguished by response
     * timing (a real SMTP round-trip vs. doing nothing) -- queuing is a
     * fast, roughly constant-time operation either way.
     */
    public function forgotPassword(string $email): void
    {
        $user = User::where('email', $email)->first();

        if ($user === null) {
            return;
        }

        $plainToken = Str::random(64);

        PasswordResetToken::where('email', $email)->delete();
        PasswordResetToken::create([
            'email' => $email,
            'token_hash' => hash('sha256', $plainToken),
            'expires_at' => now()->addMinutes(self::TOKEN_TTL_MINUTES),
        ]);

        Mail::to($email)->queue(new PasswordResetMail($plainToken));
    }

    /**
     * Consumes a password reset token: sets the new password, revokes every
     * one of the user's active sessions across all devices, and deletes the
     * token so it can never be replayed. Session revocation isn't
     * explicitly mandated by any frozen document, but is the safe default
     * consistent with this module's existing security posture (BR-3 already
     * revokes an entire session family on any suspected-compromise signal;
     * a password reset is exactly that kind of signal) -- see
     * ENGINEERING_DECISION_LOG.md.
     *
     * @throws InvalidPasswordResetTokenException
     */
    public function resetPassword(string $token, string $newPassword): void
    {
        $record = PasswordResetToken::where('token_hash', hash('sha256', $token))->first();

        if ($record === null || $record->expires_at->isPast()) {
            throw new InvalidPasswordResetTokenException;
        }

        $user = User::where('email', $record->email)->first();

        if ($user === null) {
            // Unreachable in practice (the user existed when the token was
            // issued), but treated as an invalid token rather than a 500 if
            // it somehow happens (e.g. account deleted in the interim).
            throw new InvalidPasswordResetTokenException;
        }

        $revokedTokens = DB::transaction(function () use ($user, $newPassword, $record) {
            // password_hash has a 'hashed' cast (User::casts()), so
            // assigning the plaintext here bcrypt-hashes it automatically --
            // same mechanism register() already relies on.
            $user->update(['password_hash' => $newPassword]);

            $tokens = AuthRefreshToken::where('user_id', $user->id)
                ->whereNull('revoked_at')
                ->lockForUpdate()
                ->get();

            foreach ($tokens as $refreshToken) {
                $this->tokenService->revoke($refreshToken);
            }

            PasswordResetToken::where('email', $record->email)->delete();

            return $tokens;
        });

        foreach ($revokedTokens as $refreshToken) {
            SessionRevoked::dispatch($refreshToken);
        }
    }

    /**
     * Issues an email verification token and emails it. Called by
     * SendVerificationEmail (on UserRegistered) and by the authenticated
     * resend endpoint. A no-op if the user is already verified.
     */
    public function sendVerificationEmail(User $user): void
    {
        if ($user->email_verified_at !== null) {
            return;
        }

        $plainToken = Str::random(64);

        EmailVerificationToken::where('email', $user->email)->delete();
        EmailVerificationToken::create([
            'email' => $user->email,
            'token_hash' => hash('sha256', $plainToken),
            'expires_at' => now()->addMinutes(self::TOKEN_TTL_MINUTES),
        ]);

        Mail::to($user->email)->queue(new EmailVerificationMail($plainToken));
    }

    /**
     * Consumes an email verification token: marks the account verified and
     * deletes the token so it can never be replayed.
     *
     * @throws InvalidEmailVerificationTokenException
     */
    public function verifyEmail(string $token): User
    {
        $record = EmailVerificationToken::where('token_hash', hash('sha256', $token))->first();

        if ($record === null || $record->expires_at->isPast()) {
            throw new InvalidEmailVerificationTokenException;
        }

        $user = User::where('email', $record->email)->first();

        if ($user === null) {
            throw new InvalidEmailVerificationTokenException;
        }

        $user->forceFill(['email_verified_at' => now()])->save();

        EmailVerificationToken::where('email', $record->email)->delete();

        return $user;
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
            'accessToken' => $this->tokenService->issueAccessToken($user, $device->id),
            'refreshToken' => $refresh['token'],
            'expiresIn' => $this->tokenService->accessTokenTtlSeconds(),
        ];
    }
}
