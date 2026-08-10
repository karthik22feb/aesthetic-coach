<?php

use App\Modules\Auth\Models\AuthRefreshToken;

test('an authenticated user can log out, revoking the refresh token', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $response->assertNoContent();

    $token = AuthRefreshToken::first();
    expect($token->revoked_at)->not->toBeNull();
});

test('logout requires authentication', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');

    expect(AuthRefreshToken::first()->revoked_at)->toBeNull();
});

test('logout rejects an invalid access token', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer not-a-real-token')
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401);
});

test('logout is idempotent for an already-revoked or unknown refresh token', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $first = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);
    $first->assertNoContent();

    $second = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);
    $second->assertNoContent();
});

test('logout validation requires a refreshToken', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', []);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey('refreshToken');
});
