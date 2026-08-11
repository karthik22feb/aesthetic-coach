<?php

use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\User;

test('an authenticated user can list their own sessions', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/auth/sessions');

    $response->assertOk()->assertJsonStructure([
        'data' => [['deviceId', 'deviceName', 'platform', 'lastActiveAt', 'isCurrent']],
        'apiVersion',
    ]);
    expect($response->json('data'))->toHaveCount(1);
});

test('listing sessions is rejected without authentication', function () {
    $response = $this->getJson('/api/v1/auth/sessions');

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('a user with multiple devices sees all of them listed, most recently active first', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'android',
        'deviceName' => 'Pixel 8',
    ])->assertOk();

    Device::where('device_name', 'iPhone 15')->update(['last_active_at' => now()->subDay()]);

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/auth/sessions');

    $response->assertOk();
    expect($response->json('data'))->toHaveCount(2);
    expect($response->json('data.0.deviceName'))->toBe('Pixel 8');
});

test('the device that issued the current access token is flagged isCurrent', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'android',
        'deviceName' => 'Pixel 8',
    ])->assertOk();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/auth/sessions');

    $sessions = collect($response->json('data'));
    expect($sessions->firstWhere('deviceName', 'iPhone 15')['isCurrent'])->toBeTrue();
    expect($sessions->firstWhere('deviceName', 'Pixel 8')['isCurrent'])->toBeFalse();
});

test('a device with only a revoked refresh token is excluded from the listing', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']])
        ->assertNoContent();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/auth/sessions');

    $response->assertOk();
    expect($response->json('data'))->toHaveCount(0);
});

test('a device with only an expired refresh token is excluded from the listing', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    AuthRefreshToken::first()->update(['expires_at' => now()->subDay()]);

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/auth/sessions');

    $response->assertOk();
    expect($response->json('data'))->toHaveCount(0);
});

test('the session listing never exposes token hashes or other sensitive fields', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/auth/sessions');

    $session = $response->json('data.0');
    expect($session)->toEqual([
        'deviceId' => $session['deviceId'],
        'deviceName' => $session['deviceName'],
        'platform' => $session['platform'],
        'lastActiveAt' => $session['lastActiveAt'],
        'isCurrent' => $session['isCurrent'],
    ]);
    expect($session)->not->toHaveKey('pushToken');
    expect($session)->not->toHaveKey('tokenHash');
    expect($session)->not->toHaveKey('refreshToken');
});

test('an authenticated user can revoke their own session', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $device = Device::first();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$device->id}");

    $response->assertNoContent();
    expect(AuthRefreshToken::where('device_id', $device->id)->whereNull('revoked_at')->count())->toBe(0);
});

test('revoking a session is rejected without authentication', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $device = Device::first();

    $response = $this->deleteJson("/api/v1/auth/sessions/{$device->id}");

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('a user cannot revoke another user\'s session (IDOR protection, returns 404 not 403)', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $ownDevice = Device::first();

    $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'other@example.com',
    ]))->assertCreated();
    $otherDevice = Device::where('id', '!=', $ownDevice->id)->first();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$otherDevice->id}");

    $response->assertStatus(404)->assertJsonPath('error.code', 'not_found');

    // The other user's session must remain untouched.
    expect(AuthRefreshToken::where('device_id', $otherDevice->id)->whereNull('revoked_at')->count())->toBe(1);
});

test('revoking a nonexistent session returns 404', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson('/api/v1/auth/sessions/999999');

    $response->assertStatus(404)->assertJsonPath('error.code', 'not_found');
});

test('a malformed (non-numeric) deviceId still returns the standard error envelope', function () {
    // Regression test found during PR review: {deviceId} is constrained with
    // ->whereNumber(), so a non-numeric value never reaches the controller --
    // Laravel treats it as an unmatched route and throws NotFoundHttpException
    // directly from the router, bypassing the AppException-based mapping.
    // Without an explicit render() for it (see bootstrap/app.php), this fell
    // through to Laravel's default JSON error shape instead of the app's
    // standard envelope.
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson('/api/v1/auth/sessions/not-a-number');

    $response->assertStatus(404)->assertJsonPath('error.code', 'not_found');
    expect($response->json())->toHaveKeys(['error', 'apiVersion', 'requestId']);
    expect($response->json())->not->toHaveKey('exception');
});

test('revoking an already-revoked session is idempotent', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $device = Device::first();

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$device->id}")
        ->assertNoContent();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$device->id}");

    $response->assertNoContent();
});

test('the refresh token belonging to a revoked session can no longer be used', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $device = Device::first();

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$device->id}")
        ->assertNoContent();

    $response = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'session_revoked');
});

test('revoking one device session does not affect another device session for the same user', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $second = $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'android',
        'deviceName' => 'Pixel 8',
    ])->json('data');

    $firstDevice = Device::where('device_name', 'iPhone 15')->first();

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$firstDevice->id}")
        ->assertNoContent();

    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $second['refreshToken']])
        ->assertOk();
});

test('revoking a session after it has rotated still catches the current token, not a stale one', function () {
    // True concurrent requests can't be exercised through Pest's synchronous
    // HTTP test client (same limitation as RefreshTest's sequential-replay
    // test). This instead guards the non-concurrent half of the fix made
    // during security review: revokeSession() now row-locks inside a
    // transaction (matching refresh()/revokeFamily()) instead of reading
    // active tokens then updating them unlocked, so it always operates on
    // the current row for the device, never a snapshot that a racing
    // refresh() could have already rotated out from under it.
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $device = Device::first();

    $rotated = $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])
        ->json('data');

    $this->withHeader('Authorization', 'Bearer '.$rotated['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$device->id}")
        ->assertNoContent();

    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $rotated['refreshToken']])
        ->assertStatus(401)
        ->assertJsonPath('error.code', 'session_revoked');
});

test('revoking a session already-authenticated access token is not immediately invalidated (stateless JWT security model)', function () {
    // Access tokens are stateless (ADR-0005) -- revoking a refresh token
    // invalidates future refreshes, not already-issued access tokens still
    // inside their 15-minute TTL. This is the documented tradeoff, not a bug.
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $device = Device::first();

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->deleteJson("/api/v1/auth/sessions/{$device->id}")
        ->assertNoContent();

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/auth/sessions')
        ->assertOk();
});
