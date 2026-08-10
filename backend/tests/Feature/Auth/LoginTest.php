<?php

use App\Modules\Auth\Models\Device;

beforeEach(function () {
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();
});

test('a registered user can log in with correct credentials', function () {
    $response = $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'android',
        'deviceName' => 'Pixel 8',
    ]);

    $response->assertOk()->assertJson([
        'data' => [
            'user' => ['email' => 'priya@example.com'],
            'expiresIn' => 900,
        ],
    ])->assertJsonStructure([
        'data' => ['user' => ['id', 'name', 'email', 'emailVerified'], 'accessToken', 'refreshToken', 'expiresIn'],
        'apiVersion',
    ]);

    // Login creates a second device session distinct from registration's.
    expect(Device::count())->toBe(2);
});

test('login fails with an incorrect password', function () {
    $response = $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'the-wrong-password1',
        'platform' => 'ios',
        'deviceName' => 'iPhone 15',
    ]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('login fails for a non-existent email with the same message as a wrong password', function () {
    $wrongPassword = $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'the-wrong-password1',
        'platform' => 'ios',
    ]);

    $unknownEmail = $this->postJson('/api/v1/auth/login', [
        'email' => 'nobody@example.com',
        'password' => 'the-wrong-password1',
        'platform' => 'ios',
    ]);

    $unknownEmail->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
    expect($unknownEmail->json('error.message'))->toBe($wrongPassword->json('error.message'));
});

test('login fails validation for missing fields', function (array $overrides, string $invalidField) {
    $payload = array_merge([
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'ios',
    ], $overrides);

    $response = $this->postJson('/api/v1/auth/login', $payload);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey($invalidField);
})->with([
    'missing email' => [['email' => ''], 'email'],
    'missing password' => [['password' => ''], 'password'],
    'missing platform' => [['platform' => ''], 'platform'],
]);
