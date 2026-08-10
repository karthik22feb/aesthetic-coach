<?php

test('register is rate limited to 10 requests per minute per IP', function () {
    for ($i = 1; $i <= 10; $i++) {
        $response = $this->postJson('/api/v1/auth/register', validRegistrationPayload([
            'email' => "ratelimit{$i}@example.com",
        ]));

        expect($response->status())->not->toBe(429);
    }

    $blocked = $this->postJson('/api/v1/auth/register', validRegistrationPayload([
        'email' => 'ratelimit-overflow@example.com',
    ]));

    $blocked->assertStatus(429)
        ->assertJsonPath('error.code', 'rate_limited')
        ->assertHeader('Retry-After')
        ->assertHeader('X-RateLimit-Limit', '10')
        ->assertHeader('X-RateLimit-Remaining', '0');

    expect($blocked->json('error.details.resetAt'))->not->toBeNull();
});

test('login is rate limited to 10 requests per minute per IP', function () {
    for ($i = 1; $i <= 10; $i++) {
        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'nobody@example.com',
            'password' => 'wrong-password-1',
            'platform' => 'ios',
        ]);

        expect($response->status())->not->toBe(429);
    }

    $blocked = $this->postJson('/api/v1/auth/login', [
        'email' => 'nobody@example.com',
        'password' => 'wrong-password-1',
        'platform' => 'ios',
    ]);

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});

test('logout shares the auth rate limiter and is also throttled', function () {
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    // The register call above already used 1 of the 10 shared 'auth' bucket
    // slots for this IP, so 9 more logout calls exhausts it.
    for ($i = 1; $i <= 9; $i++) {
        $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
            ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);
    }

    $blocked = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/logout', ['refreshToken' => $register['refreshToken']]);

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});
