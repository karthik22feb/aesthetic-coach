<?php

use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\TokenService;

test('a valid access token is accepted', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $response->assertNoContent();
});

test('a request with a tampered access token is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $tampered = substr($register['accessToken'], 0, -5).'AAAAA';

    $response = $this->withHeader('Authorization', 'Bearer '.$tampered)
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('a token with an unexpected issuer is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $user = User::first();

    $originalIssuer = config('jwt.issuer');
    config(['jwt.issuer' => 'a-different-issuer']);
    $forgedToken = app(TokenService::class)->issueAccessToken($user);
    config(['jwt.issuer' => $originalIssuer]);

    $response = $this->withHeader('Authorization', 'Bearer '.$forgedToken)
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('an expired access token is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $user = User::first();

    $originalTtl = config('jwt.access_ttl_minutes');
    config(['jwt.access_ttl_minutes' => -1]);
    $expiredToken = app(TokenService::class)->issueAccessToken($user);
    config(['jwt.access_ttl_minutes' => $originalTtl]);

    $response = $this->withHeader('Authorization', 'Bearer '.$expiredToken)
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('register and login remain public and never require an access token', function () {
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'ios',
    ])->assertOk();
});
