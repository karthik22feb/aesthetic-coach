<?php

test('the default CORS config never allows a wildcard origin', function () {
    expect(config('cors.allowed_origins'))->not->toContain('*');
});

test('CORS omits the allow-origin header for an unlisted origin', function () {
    $response = $this->withHeaders(['Origin' => 'https://evil.example.com'])
        ->postJson('/api/v1/auth/login', [
            'email' => 'nobody@example.com',
            'password' => 'wrong-password-1',
            'platform' => 'ios',
        ]);

    $response->assertHeaderMissing('Access-Control-Allow-Origin');
});

test('CORS allows a configured origin and rejects others in the same allow-list', function () {
    config(['cors.allowed_origins' => [
        'https://admin.aestheticcoach.app',
        'https://staging-admin.aestheticcoach.app',
    ]]);

    $allowed = $this->withHeaders(['Origin' => 'https://admin.aestheticcoach.app'])
        ->postJson('/api/v1/auth/login', [
            'email' => 'nobody@example.com',
            'password' => 'wrong-password-1',
            'platform' => 'ios',
        ]);
    $allowed->assertHeader('Access-Control-Allow-Origin', 'https://admin.aestheticcoach.app');

    $rejected = $this->withHeaders(['Origin' => 'https://evil.example.com'])
        ->postJson('/api/v1/auth/login', [
            'email' => 'nobody@example.com',
            'password' => 'wrong-password-1',
            'platform' => 'ios',
        ]);
    $rejected->assertHeaderMissing('Access-Control-Allow-Origin');
});

test('CORS does not support credentialed requests', function () {
    expect(config('cors.supports_credentials'))->toBeFalse();
});
