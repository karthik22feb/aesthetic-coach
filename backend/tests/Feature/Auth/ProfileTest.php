<?php

test('an authenticated user can view their own profile with default values', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->getJson('/api/v1/me');

    $response->assertOk()->assertJsonStructure([
        'data' => [
            'id', 'name', 'email', 'emailVerified', 'timezone', 'unitPreference',
            'dateOfBirth', 'sex', 'heightCm', 'dietaryRestrictions',
        ],
        'apiVersion',
    ]);
    $response->assertJsonPath('data.name', 'Priya Shah');
    $response->assertJsonPath('data.timezone', 'UTC');
    $response->assertJsonPath('data.unitPreference', 'metric');
    $response->assertJsonPath('data.dateOfBirth', null);
    $response->assertJsonPath('data.sex', null);
    $response->assertJsonPath('data.heightCm', null);
    $response->assertJsonPath('data.dietaryRestrictions', []);
});

test('viewing the profile is rejected without authentication', function () {
    $response = $this->getJson('/api/v1/me');

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('a single field can be updated without touching the others (partial update)', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['timezone' => 'Asia/Kolkata']);

    $response->assertOk();
    $response->assertJsonPath('data.timezone', 'Asia/Kolkata');
    // Untouched fields keep their defaults.
    $response->assertJsonPath('data.unitPreference', 'metric');
});

test('multiple fields can be updated in a single request', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', [
            'unitPreference' => 'imperial',
            'dietaryRestrictions' => ['vegetarian', 'gluten_free'],
        ]);

    $response->assertOk();
    $response->assertJsonPath('data.unitPreference', 'imperial');
    $response->assertJsonPath('data.dietaryRestrictions', ['vegetarian', 'gluten_free']);
});

test('a valid date of birth (18 or older) is accepted', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['dateOfBirth' => '1997-03-14', 'sex' => 'female', 'heightCm' => 165]);

    $response->assertOk();
    $response->assertJsonPath('data.dateOfBirth', '1997-03-14');
    $response->assertJsonPath('data.sex', 'female');
    // Laravel's JSON encoder emits a whole-number float without a forced
    // decimal point (165, not 165.0) -- assert numeric value, not PHP's
    // internal int/float type, since real API consumers never see that
    // distinction once decoded.
    expect((float) $response->json('data.heightCm'))->toBe(165.0);
});

test('a date of birth under 18 years old is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $under18 = now()->subYears(10)->toDateString();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['dateOfBirth' => $under18]);

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('dateOfBirth');
});

test('an out-of-range height is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['heightCm' => 300]);

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('heightCm');
});

test('an invalid timezone identifier is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['timezone' => 'Not/A_Real_Zone']);

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('timezone');
});

test('an invalid unit preference value is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['unitPreference' => 'furlongs']);

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('unitPreference');
});

test('email cannot be changed through PATCH /me', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['email' => 'someone-else@example.com', 'timezone' => 'Asia/Kolkata']);

    $response->assertOk();
    $response->assertJsonPath('data.email', 'priya@example.com');
    $response->assertJsonPath('data.timezone', 'Asia/Kolkata');
});

test('updating the profile is rejected without authentication', function () {
    $response = $this->patchJson('/api/v1/me', ['timezone' => 'Asia/Kolkata']);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('/me uses the general API rate limiter, not the 10/min auth limiter', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    // The 'auth' limiter (10/min per IP) would already be exhausted well
    // before this many requests if /me shared it -- confirms the routes.php
    // grouping decision (throttle:api, not throttle:auth) actually took effect.
    for ($i = 0; $i < 15; $i++) {
        $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
            ->getJson('/api/v1/me');
        $response->assertOk();
    }
});

test('a nullable field can be explicitly cleared back to null after being set', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['sex' => 'female', 'dietaryRestrictions' => ['vegetarian']])
        ->assertOk();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['sex' => null, 'dietaryRestrictions' => null]);

    $response->assertOk();
    $response->assertJsonPath('data.sex', null);
    $response->assertJsonPath('data.dietaryRestrictions', []);
});

test('an empty name is rejected', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->patchJson('/api/v1/me', ['name' => '']);

    $response->assertStatus(422)->assertJsonPath('error.code', 'validation_failed');
    expect($response->json('error.details'))->toHaveKey('name');
});
