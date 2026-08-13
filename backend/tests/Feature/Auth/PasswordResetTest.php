<?php

use App\Modules\Auth\Mail\PasswordResetMail;
use App\Modules\Auth\Models\AuthRefreshToken;
use App\Modules\Auth\Models\PasswordResetToken;
use Illuminate\Support\Facades\Mail;

test('a valid forgot-password request for an existing user returns the generic response and queues the email', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    $response = $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com']);

    $response->assertOk();
    expect($response->json('data.message'))->toBe('If an account exists for this email, a password reset link has been sent.');
    Mail::assertQueued(PasswordResetMail::class);
});

test('a forgot-password request for an unknown email returns the identical generic response and queues nothing', function () {
    Mail::fake();

    $response = $this->postJson('/api/v1/auth/password/forgot', ['email' => 'nobody@example.com']);

    $response->assertOk();
    expect($response->json('data.message'))->toBe('If an account exists for this email, a password reset link has been sent.');
    Mail::assertNothingQueued();
});

test('forgot-password never reveals whether the email exists via a different status or error shape', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    $known = $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com']);
    $unknown = $this->postJson('/api/v1/auth/password/forgot', ['email' => 'nobody@example.com']);

    expect($known->getStatusCode())->toBe($unknown->getStatusCode());
    expect($known->json())->toEqual($unknown->json());
});

test('forgot-password validation requires a well-formed email', function () {
    $response = $this->postJson('/api/v1/auth/password/forgot', ['email' => 'not-an-email']);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey('email');
});

test('a reset request generates a single-use token hashed in storage, never in plaintext', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();

    $record = PasswordResetToken::where('email', 'priya@example.com')->first();
    expect($record)->not->toBeNull();
    expect($record->token_hash)->toHaveLength(64);

    $capturedToken = null;
    Mail::assertQueued(PasswordResetMail::class, function ($mail) use (&$capturedToken) {
        $capturedToken = $mail->token;

        return true;
    });

    expect($record->token_hash)->toBe(hash('sha256', $capturedToken));
    expect($record->token_hash)->not->toBe($capturedToken);
});

test('a valid password reset changes the password, and the old password no longer works', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();
    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();

    $token = null;
    Mail::assertQueued(PasswordResetMail::class, function ($mail) use (&$token) {
        $token = $mail->token;

        return true;
    });

    $response = $this->postJson('/api/v1/auth/password/reset', [
        'token' => $token,
        'password' => 'new-correct-horse2',
    ]);
    $response->assertNoContent();

    $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'ios',
    ])->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');

    $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'new-correct-horse2',
        'platform' => 'ios',
    ])->assertOk();
});

test('resetting the password revokes every active session across all devices', function () {
    Mail::fake();
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    $secondDevice = $this->postJson('/api/v1/auth/login', [
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'android',
        'deviceName' => 'Pixel',
    ])->json('data');

    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();
    $token = null;
    Mail::assertQueued(PasswordResetMail::class, function ($mail) use (&$token) {
        $token = $mail->token;

        return true;
    });

    $this->postJson('/api/v1/auth/password/reset', ['token' => $token, 'password' => 'new-correct-horse2'])
        ->assertNoContent();

    expect(AuthRefreshToken::whereNull('revoked_at')->count())->toBe(0);

    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $register['refreshToken']])
        ->assertStatus(401)->assertJsonPath('error.code', 'session_revoked');
    $this->postJson('/api/v1/auth/refresh', ['refreshToken' => $secondDevice['refreshToken']])
        ->assertStatus(401)->assertJsonPath('error.code', 'session_revoked');
});

test('an invalid (never-issued) reset token is rejected', function () {
    $response = $this->postJson('/api/v1/auth/password/reset', [
        'token' => 'totally-garbage-never-issued',
        'password' => 'new-correct-horse2',
    ]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('an expired reset token is rejected', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();
    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();

    $token = null;
    Mail::assertQueued(PasswordResetMail::class, function ($mail) use (&$token) {
        $token = $mail->token;

        return true;
    });
    PasswordResetToken::where('email', 'priya@example.com')->update(['expires_at' => now()->subMinute()]);

    $response = $this->postJson('/api/v1/auth/password/reset', ['token' => $token, 'password' => 'new-correct-horse2']);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('an already-used reset token cannot be reused (single-use)', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();
    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();

    $token = null;
    Mail::assertQueued(PasswordResetMail::class, function ($mail) use (&$token) {
        $token = $mail->token;

        return true;
    });

    $this->postJson('/api/v1/auth/password/reset', ['token' => $token, 'password' => 'new-correct-horse2'])
        ->assertNoContent();

    $replay = $this->postJson('/api/v1/auth/password/reset', ['token' => $token, 'password' => 'another-password3']);

    $replay->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('a new forgot-password request invalidates a previously issued, unused token', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();
    $firstToken = null;
    Mail::assertQueued(PasswordResetMail::class, function ($mail) use (&$firstToken) {
        $firstToken = $mail->token;

        return true;
    });

    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();

    $response = $this->postJson('/api/v1/auth/password/reset', ['token' => $firstToken, 'password' => 'new-correct-horse2']);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('reset validation enforces the same password policy as registration', function () {
    $response = $this->postJson('/api/v1/auth/password/reset', ['token' => 'whatever', 'password' => 'short1']);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey('password');
});

test('reset validation requires a token', function () {
    $response = $this->postJson('/api/v1/auth/password/reset', ['password' => 'new-correct-horse2']);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey('token');
});

test('the forgot-password endpoint is rate limited', function () {
    Mail::fake();

    for ($i = 1; $i <= 10; $i++) {
        $this->postJson('/api/v1/auth/password/forgot', ['email' => "garbage-$i@example.com"]);
    }

    $blocked = $this->postJson('/api/v1/auth/password/forgot', ['email' => 'garbage-11@example.com']);

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});

test('the reset-password endpoint is rate limited', function () {
    for ($i = 1; $i <= 10; $i++) {
        $this->postJson('/api/v1/auth/password/reset', ['token' => "garbage-$i", 'password' => 'new-correct-horse2']);
    }

    $blocked = $this->postJson('/api/v1/auth/password/reset', ['token' => 'garbage-11', 'password' => 'new-correct-horse2']);

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});

test('the plaintext reset token is never present in any API response body', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    $response = $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com']);

    expect(json_encode($response->json()))->not->toContain('token');
});

test('reset-password does not require an access token (it is a public endpoint)', function () {
    Mail::fake();
    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();
    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'priya@example.com'])->assertOk();

    $token = null;
    Mail::assertQueued(PasswordResetMail::class, function ($mail) use (&$token) {
        $token = $mail->token;

        return true;
    });

    $this->postJson('/api/v1/auth/password/reset', ['token' => $token, 'password' => 'new-correct-horse2'])
        ->assertNoContent();
});
