<?php

use App\Modules\Auth\Enums\UnitPreference;
use App\Modules\Auth\Models\User;

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

test("updating one user's profile does not affect another user's profile (cross-user isolation)", function () {
    // /me has no ID in the URL -- it is scoped entirely by the bearer
    // token's resolved user (routes.php), so the IDOR-style check this
    // project's other resource-scoped endpoints run as "user A cannot
    // access user B's resource by ID" doesn't literally apply here. The
    // equivalent real risk for a token-scoped singleton resource is a
    // bug that resolves or writes the wrong user row -- this asserts
    // user B's row is byte-for-byte unaffected by user A's update.
    //
    // Deliberately verified via a direct User query, not a second
    // authenticated request as user B: Laravel's `Auth::viaRequest()`
    // guard (RequestGuard::user()) caches the resolved user on the guard
    // instance, and that guard is cached per-name on the shared AuthManager
    // singleton -- which is not rebuilt between requests inside a single
    // Pest test's HTTP calls. A second `withHeader(...)->getJson(...)`
    // call here would silently resolve to the *first* request's cached
    // user, not user B's, regardless of which bearer token is sent. This
    // is a test-harness quirk, not a production behavior (every real
    // HTTP request gets a fresh container) -- see SessionTest.php's own
    // IDOR test for the same already-established pattern of verifying
    // the other user's state directly rather than via a second
    // authenticated call.
    $userA = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'imaan@example.com',
    ]))->assertCreated();

    $this->withHeader('Authorization', 'Bearer '.$userA['accessToken'])
        ->patchJson('/api/v1/me', [
            'timezone' => 'Asia/Kolkata',
            'unitPreference' => 'imperial',
            'dietaryRestrictions' => ['vegan'],
        ])
        ->assertOk();

    $userB = User::where('email', 'imaan@example.com')->first();

    expect($userB->timezone)->toBe('UTC');
    expect($userB->unit_preference)->toBe(UnitPreference::Metric);
    // The raw model attribute is null until a value is ever set -- the API
    // response's `[]` default (asserted elsewhere in this file) is a
    // UserResource-layer normalization, not the underlying column/cast
    // value, which this direct-model query reads unmediated.
    expect($userB->dietary_restrictions)->toBeNull();
});
