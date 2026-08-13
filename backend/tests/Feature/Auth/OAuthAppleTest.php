<?php

use App\Modules\Auth\Contracts\OAuthTokenVerifier;
use App\Modules\Auth\Enums\OAuthProvider;
use App\Modules\Auth\Exceptions\InvalidOAuthTokenException;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\OAuthIdentity;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\AppleIdTokenVerifier;
use App\Modules\Auth\Support\OAuthClaims;

/*
|--------------------------------------------------------------------------
| Apple OAuth flow tests
|--------------------------------------------------------------------------
|
| Mirrors OAuthGoogleTest.php -- see that file's header comment for why the
| verifier itself is mocked here rather than re-testing cryptography
| (covered by OAuthTokenVerifierTest.php). These tests focus on the two
| things genuinely different about Apple per docs/features/authentication.md
| Edge Cases: Apple's ID token never includes a 'name' claim, and a private
| relay email must never be treated as matching a user's real email.
|
*/

function fakeAppleVerifier(array $responses): void
{
    app()->instance(AppleIdTokenVerifier::class, new class($responses) implements OAuthTokenVerifier
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

function applePayload(array $overrides = []): array
{
    return array_merge([
        'idToken' => 'valid-token',
        'platform' => 'ios',
        'deviceName' => 'iPhone 15',
    ], $overrides);
}

test('a valid Apple credential for a brand-new email creates a user and issues a session', function () {
    fakeAppleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Apple, 'apple-sub-1', 'newapple@example.com', true),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/apple', applePayload());

    $response->assertCreated()->assertJsonStructure([
        'data' => ['user' => ['id', 'name', 'email', 'emailVerified'], 'accessToken', 'refreshToken', 'expiresIn'],
        'apiVersion',
    ]);

    $user = User::where('email', 'newapple@example.com')->first();
    // Apple's ID token never carries a 'name' claim -- confirms the same
    // email-local-part fallback used when Google omits it too.
    expect($user->name)->toBe('newapple');
    expect($user->password_hash)->toBeNull();
    expect(OAuthIdentity::where('user_id', $user->id)->where('provider', OAuthProvider::Apple)->exists())->toBeTrue();
    expect(Device::where('user_id', $user->id)->where('device_name', 'iPhone 15')->exists())->toBeTrue();
});

test('signing in again with the same Apple identity resolves the same user, does not duplicate', function () {
    fakeAppleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Apple, 'apple-sub-2', 'repeat-apple@example.com', true),
    ]);

    $first = $this->postJson('/api/v1/auth/oauth/apple', applePayload())->json('data');
    $second = $this->postJson('/api/v1/auth/oauth/apple', applePayload(['deviceName' => 'iPad']))->json('data');

    expect($first['user']['id'])->toBe($second['user']['id']);
    expect(User::where('email', 'repeat-apple@example.com')->count())->toBe(1);
});

test('a private relay email is treated as an ordinary unique email, never merged with a real-email account', function () {
    // Per docs/features/authentication.md Edge Cases: private relay emails
    // are NOT auto-merged with a later real-email account -- there's no
    // dedicated merge logic to test here; this confirms the generic
    // email-matching path naturally does the documented right thing simply
    // because the two addresses never coincide.
    $realEmailUser = $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'priya.real@example.com',
    ]))->json('data')['user'];

    fakeAppleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Apple, 'apple-sub-3', 'abc123@privaterelay.appleid.com', true),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/apple', applePayload());

    $response->assertCreated();
    expect($response->json('data.user.id'))->not->toBe($realEmailUser['id']);
    expect(User::count())->toBe(2);
});

test('a verified Apple email matching an existing password account links instead of duplicating', function () {
    $existing = $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'apple-link@example.com',
    ]))->json('data')['user'];

    fakeAppleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Apple, 'apple-sub-4', 'apple-link@example.com', true),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/apple', applePayload());

    $response->assertOk();
    expect($response->json('data.user.id'))->toBe($existing['id']);
    expect(User::where('email', 'apple-link@example.com')->count())->toBe(1);
});

test('an unverified Apple email matching an existing account is refused, not linked', function () {
    $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'apple-unverified@example.com',
    ]))->assertCreated();

    fakeAppleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Apple, 'apple-sub-5', 'apple-unverified@example.com', false),
    ]);

    $response = $this->postJson('/api/v1/auth/oauth/apple', applePayload());

    $response->assertStatus(409)->assertJsonPath('error.code', 'conflict');
});

test('an invalid Apple credential is rejected with 401', function () {
    fakeAppleVerifier([]);

    $response = $this->postJson('/api/v1/auth/oauth/apple', applePayload(['idToken' => 'garbage-token']));

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('Apple sign-in validation requires an idToken and platform', function () {
    $response = $this->postJson('/api/v1/auth/oauth/apple', ['deviceName' => 'iPhone']);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKeys(['idToken', 'platform']);
});

test('an Apple sign-in issues a working access token and refresh token', function () {
    fakeAppleVerifier([
        'valid-token' => new OAuthClaims(OAuthProvider::Apple, 'apple-sub-6', 'apple-tokens@example.com', true),
    ]);

    $session = $this->postJson('/api/v1/auth/oauth/apple', applePayload())->json('data');

    $this->withHeader('Authorization', 'Bearer '.$session['accessToken'])
        ->getJson('/api/v1/auth/sessions')
        ->assertOk();

    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $session['refreshToken']])
        ->assertOk();
});
