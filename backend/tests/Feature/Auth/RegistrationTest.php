<?php

use App\Modules\Auth\Enums\Platform;
use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\Device;
use App\Modules\Auth\Models\User;
use Illuminate\Support\Facades\Hash;

test('a user can register with valid data', function () {
    $response = $this->postJson('/api/v1/auth/register', validRegistrationPayload());

    $response->assertCreated()->assertJson([
        'data' => [
            'user' => [
                'name' => 'Priya Shah',
                'email' => 'priya@example.com',
                'emailVerified' => false,
            ],
            'expiresIn' => 900,
        ],
    ])->assertJsonStructure([
        'data' => ['user' => ['id', 'name', 'email', 'emailVerified'], 'accessToken', 'refreshToken', 'expiresIn'],
        'apiVersion',
    ]);

    $user = User::where('email', 'priya@example.com')->first();
    expect($user)->not->toBeNull();
    expect($user->password_hash)->not->toBe('correct-horse-battery1');
    expect(Hash::check('correct-horse-battery1', $user->password_hash))->toBeTrue();

    expect(Device::where('user_id', $user->id)->count())->toBe(1);
    expect(AuthRefreshToken::where('user_id', $user->id)->count())->toBe(1);
});

test('registration creates a device with the submitted platform and device name', function () {
    $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'platform' => 'android',
        'deviceName' => 'Pixel 8',
    ]))->assertCreated();

    $device = Device::first();
    expect($device->platform)->toBe(Platform::Android);
    expect($device->device_name)->toBe('Pixel 8');
});

test('registration defaults the device name when omitted', function () {
    $payload = validRegistrationPayload();
    unset($payload['deviceName']);

    $this->postJson('/api/v1/auth/register', $payload)->assertCreated();

    expect(Device::first()->device_name)->not->toBeEmpty();
});

test('registration fails with a duplicate email', function () {
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    $response = $this->postJson('/api/v1/auth/register', validRegistrationPayload());

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('email');

    expect(User::count())->toBe(1);
});

test('registration fails validation for missing or invalid fields', function (array $overrides, string $invalidField) {
    $response = $this->postJson('/api/v1/auth/register', validRegistrationPayload($overrides));

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey($invalidField);
})->with([
    'missing name' => [['name' => ''], 'name'],
    'invalid email' => [['email' => 'not-an-email'], 'email'],
    'missing platform' => [['platform' => ''], 'platform'],
    'invalid platform' => [['platform' => 'windows'], 'platform'],
]);

test('registration enforces the password policy (BR-1)', function (string $password) {
    $response = $this->postJson('/api/v1/auth/register', validRegistrationPayload(['password' => $password]));

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey('password');
})->with([
    'too short' => ['short1'],
    'no digit' => ['correct-horse-battery'],
    'no letter' => ['1234567890'],
]);
