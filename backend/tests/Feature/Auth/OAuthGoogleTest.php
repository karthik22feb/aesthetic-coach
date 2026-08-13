<?php

use App\Modules\Auth\Contracts\OAuthTokenVerifier;
use App\Modules\Auth\Enums\OAuthProvider;
use App\Modules\Auth\Exceptions\InvalidOAuthTokenException;
use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\OAuthIdentity;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\GoogleIdTokenVerifier;
use App\Modules\Auth\Support\OAuthClaims;

/*
|--------------------------------------------------------------------------
| Google OAuth flow tests
|--------------------------------------------------------------------------
|
| The verifier's own signature/issuer/audience/expiration checks are
| exercised with real cryptography in OAuthTokenVerifierTest.php. These
| tests instead mock GoogleIdTokenVerifier itself (bound in the container)
| to return canned, already-verified claims, so the flow tests focus purely
| on AuthService::oauthLogin()'s account-resolution and session-issuance
| logic -- exactly what this session's testing brief asks for ("mock
| external provider verification where appropriate").
|
*/

function fakeGoogleVerifier(array $responses): void
{
    app()->instance(GoogleIdTokenVerifier::class, new class($responses) implements OAuthTokenVerifier
    {
        public function __construct(private array $responses) {}

        public function verify(string $idToken): OAuthClaims
        {
            if (! isset($this->responses[$idToken])) {
                throw new InvalidOAuthTokenException;
            }

            return $this->responses[$idToken];
        }
    });
}

function googlePayload(array $overrides = []): array
{
    return array_merge([
        'idToken' => 'valid-token',
        'platform' => 'ios',
        'deviceName' => 'iPhone 15',
    ], $overrides);
}

test('a valid Google credential for a brand-new email creates a user and issues a session', function () {
    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-1', 'newgoogle@example.com', true, 'Priya Shah'),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/google', googlePayload());

    $response->assertCreated()->assertJsonStructure([
        'data' => ['user' => ['id', 'name', 'email', 'emailVerified'], 'accessToken', 'refreshToken', 'expiresIn'],
        'apiVersion',
    ]);
    expect($response->json('data.user.email'))->toBe('newgoogle@example.com');
    expect($response->json('data.user.name'))->toBe('Priya Shah');
    expect($response->json('data.user.emailVerified'))->toBeTrue();

    $user = User::where('email', 'newgoogle@example.com')->first();
    expect($user->password_hash)->toBeNull();
    expect(OAuthIdentity::where('user_id', $user->id)->where('provider', OAuthProvider::Google)->exists())->toBeTrue();
    expect(Device::where('user_id', $user->id)->where('device_name', 'iPhone 15')->exists())->toBeTrue();
});

test('a Google credential with no name claim falls back to a derived name', function () {
    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-2', 'noname@example.com', true, null),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/google', googlePayload());

    $response->assertCreated();
    expect($response->json('data.user.name'))->toBe('noname');
});

test('signing in again with the same Google identity resolves the same user, does not duplicate', function () {
    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-3', 'repeat@example.com', true, 'Repeat User'),
    ]);

    $first = $this->postJson('/api/v1/auth/oauth/google', googlePayload())->json('data');
    $second = $this->postJson('/api/v1/auth/oauth/google', googlePayload(['deviceName' => 'Second Device']))->json('data');

    expect($first['user']['id'])->toBe($second['user']['id']);
    expect(User::where('email', 'repeat@example.com')->count())->toBe(1);
    expect(OAuthIdentity::where('provider', OAuthProvider::Google)->where('provider_user_id', 'google-sub-3')->count())->toBe(1);
});

test('the second sign-in for an existing identity returns 200, not 201', function () {
    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-4', 'status@example.com', true),
    ]);

    $this->postJson('/api/v1/auth/oauth/google', googlePayload())->assertCreated();
    $this->postJson('/api/v1/auth/oauth/google', googlePayload())->assertOk();
});

test('a Google credential with a verified email matching an existing password account links instead of duplicating', function () {
    $existing = $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'linkme@example.com',
    ]))->json('data')['user'];

    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-5', 'linkme@example.com', true, 'Link Me'),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/google', googlePayload());

    $response->assertOk();
    expect($response->json('data.user.id'))->toBe($existing['id']);
    expect(User::where('email', 'linkme@example.com')->count())->toBe(1);
    expect(OAuthIdentity::where('user_id', $existing['id'])->where('provider', OAuthProvider::Google)->exists())->toBeTrue();
});

test('a Google credential with an unverified email matching an existing account is refused, not linked', function () {
    $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'unverified-collision@example.com',
    ]))->assertCreated();

    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-6', 'unverified-collision@example.com', false, 'Attacker Claim'),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/google', googlePayload());

    $response->assertStatus(409)->assertJsonPath('error.code', 'conflict');
    expect(OAuthIdentity::where('provider', OAuthProvider::Google)->where('provider_user_id', 'google-sub-6')->exists())->toBeFalse();
});

test('an invalid Google credential (bad signature, expired, wrong issuer/audience) is rejected with 401', function () {
    fakeGoogleVerifier([]);

    $response = $this->postJson('/api/v1/auth/oauth/google', googlePayload(['idToken' => 'garbage-token']));

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('Google sign-in validation requires an idToken and platform', function () {
    $response = $this->postJson('/api/v1/auth/oauth/google', ['deviceName' => 'iPhone']);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKeys(['idToken', 'platform']);
});

test('a Google sign-in issues a working access token and rotating refresh token', function () {
    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-7', 'tokens@example.com', true),
    ]);

    $session = $this->postJson('/api/v1/auth/oauth/google', googlePayload())->json('data');

    $this->withHeader('Authorization', 'Bearer '.$session['accessToken'])
        ->getJson('/api/v1/auth/sessions')
        ->assertOk();

    $refreshed = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $session['refreshToken']]);
    $refreshed->assertOk();

    expect(AuthRefreshToken::count())->toBe(2);
});

test('Google sign-in never exposes password_hash or provider_user_id in the response', function () {
    fakeGoogleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Google, 'google-sub-8', 'nosecrets@example.com', true),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/google', googlePayload());

    $user = $response->json('data.user');
    expect($user)->not->toHaveKey('password_hash');
    expect($user)->not->toHaveKey('providerUserId');
    expect($user)->not->toHaveKey('provider_user_id');
});

test('Google sign-in shares the auth rate limiter', function () {
    fakeGoogleVerifier([]);

    for ($i = 1; $i <= 10; $i++) {
        $this->postJson('/api/v1/auth/oauth/google', googlePayload(['idToken' => "garbage-$i"]));
    }

    $blocked = $this->postJson('/api/v1/auth/oauth/google', googlePayload(['idToken' => 'garbage-11']));

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});
