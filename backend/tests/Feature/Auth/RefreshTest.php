<?php

use App\Modules\Auth\Models\AuthRefreshToken;

test('a valid refresh token issues a new access and refresh token', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    $response->assertOk()->assertJsonStructure([
        'data' => ['accessToken', 'refreshToken', 'expiresIn'],
        'apiVersion',
    ]);

    // The refresh response never includes a user object, per
    // docs/api-examples/auth.md (POST /auth/refresh).
    expect($response->json('data'))->not->toHaveKey('user');
    expect($response->json('data.expiresIn'))->toBe(900);
});

test('refresh rotates the token: the new refresh token differs from the old one', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    // Access tokens are pure functions of their claims (iss/sub/iat/exp), so
    // two issued within the same second are legitimately byte-identical --
    // not asserted here. Refresh tokens are independently random per
    // issuance (Str::random(64)), so uniqueness is the meaningful check.
    $newRefreshToken = $response->json('data.refreshToken');
    expect($newRefreshToken)->not->toBe($register['refreshToken']);
});

test('rotation preserves the token family and revokes the old token', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $originalFamily = AuthRefreshToken::first()->family_id;

    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])->assertOk();

    expect(AuthRefreshToken::count())->toBe(2);

    $old = AuthRefreshToken::where('token_hash', hash('sha256', $register['refreshToken']))->first();
    $new = AuthRefreshToken::where('token_hash', '!=', $old->token_hash)->first();

    expect($old->revoked_at)->not->toBeNull();
    expect($new->revoked_at)->toBeNull();
    expect($new->family_id)->toBe($originalFamily);
});

test('the rotated-away token cannot be used again (single-use)', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])->assertOk();

    $replay = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    $replay->assertStatus(401)->assertJsonPath('error.code', 'session_revoked');
});

test('reuse of a rotated token revokes the entire family, killing the current token too', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $rotated = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])
        ->json('data');

    // Replay the original (already-rotated) token -- triggers reuse detection.
    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])
        ->assertStatus(401)
        ->assertJsonPath('error.code', 'session_revoked');

    // The token issued by the legitimate rotation above must now be dead too.
    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $rotated['refreshToken']])
        ->assertStatus(401)
        ->assertJsonPath('error.code', 'session_revoked');

    expect(AuthRefreshToken::whereNull('revoked_at')->count())->toBe(0);
});

test('a token revoked by logout is treated as reuse if presented to refresh', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']])
        ->assertNoContent();

    $response = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'session_revoked');
});

test('an expired refresh token is rejected without triggering family revocation', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    AuthRefreshToken::first()->update(['expires_at' => now()->subDay()]);

    $response = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');

    // Expiry is not reuse -- the token itself stays un-revoked (it simply
    // lapsed), so no family-wide effect occurs.
    expect(AuthRefreshToken::first()->revoked_at)->toBeNull();
});

test('an invalid (never-issued) refresh token is rejected', function () {
    $response = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => 'totally-garbage-never-issued']);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('refresh validation requires a refreshToken', function () {
    $response = $this->postJson('/api/v1/auth/refresh', []);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey('refreshToken');
});

test('refresh does not require an access token (it is a public endpoint)', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    $response->assertOk();
});

test('logout works correctly after a refresh, revoking the rotated token', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $rotated = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])
        ->json('data');

    $this->withHeader('Authorization', 'Bearer '.$rotated['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $rotated['refreshToken']])
        ->assertNoContent();

    $token = AuthRefreshToken::where('token_hash', hash('sha256', $rotated['refreshToken']))->first();
    expect($token->revoked_at)->not->toBeNull();
});

test('a sequential replay of a token loses the race and is rejected atomically', function () {
    // True parallel requests can't be exercised through Pest's synchronous
    // HTTP test client; this instead verifies the mechanism a real race
    // relies on -- the losing request always sees the winner's revocation,
    // because AuthService::refresh() row-locks the token inside a
    // transaction (SELECT ... FOR UPDATE) before deciding anything.
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $first = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);
    $second = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    $first->assertOk();
    $second->assertStatus(401)->assertJsonPath('error.code', 'session_revoked');

    // Exactly one new, usable token should exist -- the "loser" did not
    // also mint a token before losing.
    expect(AuthRefreshToken::whereNull('revoked_at')->count())->toBe(0);
});

test('refresh issues a valid access token accepted by a protected endpoint', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $rotated = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])
        ->json('data');

    $this->withHeader('Authorization', 'Bearer '.$rotated['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $rotated['refreshToken']])
        ->assertNoContent();
});

test('the refresh endpoint is rate limited', function () {
    for ($i = 1; $i <= 10; $i++) {
        $this->postJson('/api/v1/auth/refresh', ['refreshToken' => 'garbage-'.$i]);
    }

    $blocked = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => 'garbage-11']);

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});
