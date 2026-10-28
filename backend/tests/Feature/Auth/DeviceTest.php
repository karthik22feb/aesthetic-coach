<?php

use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\TokenService;

test('an authenticated user can register a push token for their current device', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/devices', ['pushToken' => 'fcm-token-abc123']);

    $response->assertNoContent();
    expect(Device::where('device_name', 'iPhone 15')->first()->push_token)->toBe('fcm-token-abc123');
});

test('registering a push token is rejected without authentication', function () {
    $response = $this->postJson('/api/v1/devices', ['pushToken' => 'fcm-token-abc123']);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('an empty push token is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/devices', ['pushToken' => '']);

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('pushToken');
});

test('a missing push token is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/devices', []);

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('pushToken');
});

test('registering a push token is idempotent -- re-registering with a new token overwrites the old one, not a second row', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/devices', ['pushToken' => 'first-token'])
        ->assertNoContent();

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/devices', ['pushToken' => 'second-token'])
        ->assertNoContent();

    expect(Device::where('device_name', 'iPhone 15')->count())->toBe(1);
    expect(Device::where('device_name', 'iPhone 15')->first()->push_token)->toBe('second-token');
});

test("registering a push token on one device does not touch another user's device", function () {
    $userA = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $ownDevice = Device::first();

    $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'other@example.com',
    ]))->assertCreated();
    $otherDevice = Device::where('id', '!=', $ownDevice->id)->first();

    $this->withHeader('Authorization', 'Bearer '.$userA['accessToken'])
        ->postJson('/api/v1/devices', ['pushToken' => 'my-token'])
        ->assertNoContent();

    expect($otherDevice->refresh()->push_token)->toBeNull();
});

test('a token with no device claim (did) is rejected as not found, not a server error', function () {
    // Every token issued via register()/login()/refresh() carries a `did`
    // claim (ENGINEERING_DECISION_LOG.md, 2026-08-11) -- this crafts one
    // without it, the same way JwtValidationTest.php forges tokens for
    // other edge cases, to prove registerPushToken() fails closed
    // (404, not a 500/crash) rather than assuming the claim is always
    // present.
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();
    $user = User::where('email', 'priya@example.com')->first();
    $tokenWithNoDeviceClaim = app(TokenService::class)->issueAccessToken($user);

    $response = $this->withHeader('Authorization', 'Bearer '.$tokenWithNoDeviceClaim)
        ->postJson('/api/v1/devices', ['pushToken' => 'fcm-token-abc123']);

    $response->assertStatus(404)->assertJsonPath('error.code', 'not_found');
    // The original device (and the one register() actually created) is
    // confirmed untouched.
    expect(Device::where('device_name', 'iPhone 15')->first()->push_token)->toBeNull();
});
