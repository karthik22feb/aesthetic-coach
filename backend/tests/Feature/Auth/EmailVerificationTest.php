<?php

use App\Modules\Auth\Mail\EmailVerificationMail;
use App\Modules\Auth\Models\EmailVerificationToken;
use App\Modules\Auth\Models\User;
use Illuminate\Support\Facades\Mail;

function registerAndCaptureVerificationToken(array $overrides = []): array
{
    Mail::fake();
    $register = test()->postJson('/api/v1/auth/register', validRegistrationPayload($overrides))->assertCreated()->json('data');

    $token = null;
    Mail::assertQueued(EmailVerificationMail::class, function ($mail) use (&$token) {
        $token = $mail->token;

        return true;
    });

    return [$register, $token];
}

test('registering a new account queues a verification email', function () {
    Mail::fake();

    $this->postJson('/api/v1/auth/register', validRegistrationPayload())->assertCreated();

    Mail::assertQueued(EmailVerificationMail::class);
});

test('a new account starts unverified', function () {
    $response = $this->postJson('/api/v1/auth/register', validRegistrationPayload());

    expect($response->json('data.user.emailVerified'))->toBeFalse();
});

test('a valid verification token marks the account verified and persists it', function () {
    [$register, $token] = registerAndCaptureVerificationToken();

    $response = $this->postJson('/api/v1/auth/email/verify', ['token' => $token]);

    $response->assertOk();
    expect($response->json('data.user.emailVerified'))->toBeTrue();

    $user = User::where('email', 'priya@example.com')->first();
    expect($user->email_verified_at)->not->toBeNull();
});

test('an invalid (never-issued) verification token is rejected', function () {
    $response = $this->postJson('/api/v1/auth/email/verify', ['token' => 'totally-garbage-never-issued']);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('a malformed verification token string is rejected the same as any other invalid token', function () {
    $response = $this->postJson('/api/v1/auth/email/verify', ['token' => '!!!not-a-real-token-format???']);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('an expired verification token is rejected', function () {
    [, $token] = registerAndCaptureVerificationToken();

    EmailVerificationToken::where('email', 'priya@example.com')->update(['expires_at' => now()->subMinute()]);

    $response = $this->postJson('/api/v1/auth/email/verify', ['token' => $token]);

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');

    $user = User::where('email', 'priya@example.com')->first();
    expect($user->email_verified_at)->toBeNull();
});

test('an already-used verification token cannot be reused (single-use)', function () {
    [, $token] = registerAndCaptureVerificationToken();

    $this->postJson('/api/v1/auth/email/verify', ['token' => $token])->assertOk();

    $replay = $this->postJson('/api/v1/auth/email/verify', ['token' => $token]);

    $replay->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('verification validation requires a token', function () {
    $response = $this->postJson('/api/v1/auth/email/verify', []);

    $response->assertStatus(422);
    expect($response->json('error.details'))->toHaveKey('token');
});

test('the verification token is stored hashed, never in plaintext', function () {
    [, $token] = registerAndCaptureVerificationToken();

    $record = EmailVerificationToken::where('email', 'priya@example.com')->first();

    expect($record->token_hash)->toHaveLength(64);
    expect($record->token_hash)->toBe(hash('sha256', $token));
    expect($record->token_hash)->not->toBe($token);
});

test('an authenticated user can request another verification email', function () {
    Mail::fake();
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');
    Mail::fake();

    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/email/resend');

    $response->assertNoContent();
    Mail::assertQueued(EmailVerificationMail::class);
});

test('resending verification is rejected without authentication', function () {
    $response = $this->postJson('/api/v1/auth/email/resend');

    $response->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');
});

test('resending verification for an already-verified account is a no-op and sends nothing', function () {
    [$register, $token] = registerAndCaptureVerificationToken();
    $this->postJson('/api/v1/auth/email/verify', ['token' => $token])->assertOk();

    Mail::fake();
    $response = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/email/resend');

    $response->assertNoContent();
    Mail::assertNothingQueued();
});

test('resending verification issues a new token that invalidates the previous one', function () {
    [$register, $firstToken] = registerAndCaptureVerificationToken();

    Mail::fake();
    $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/email/resend')
        ->assertNoContent();

    $secondToken = null;
    Mail::assertQueued(EmailVerificationMail::class, function ($mail) use (&$secondToken) {
        $secondToken = $mail->token;

        return true;
    });

    expect($secondToken)->not->toBe($firstToken);

    $this->postJson('/api/v1/auth/email/verify', ['token' => $firstToken])
        ->assertStatus(401)->assertJsonPath('error.code', 'unauthenticated');

    $this->postJson('/api/v1/auth/email/verify', ['token' => $secondToken])->assertOk();
});

test('the email verify endpoint is rate limited', function () {
    for ($i = 1; $i <= 10; $i++) {
        $this->postJson('/api/v1/auth/email/verify', ['token' => "garbage-$i"]);
    }

    $blocked = $this->postJson('/api/v1/auth/email/verify', ['token' => 'garbage-11']);

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});

test('the email resend endpoint is rate limited', function () {
    Mail::fake();
    $register = $this->postJson('/api/v1/auth/register', validRegistrationPayload())->json('data');

    for ($i = 1; $i <= 9; $i++) {
        $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
            ->postJson('/api/v1/auth/email/resend');
    }

    $blocked = $this->withHeader('Authorization', 'Bearer '.$register['accessToken'])
        ->postJson('/api/v1/auth/email/resend');

    $blocked->assertStatus(429)->assertJsonPath('error.code', 'rate_limited');
});

test('the plaintext verification token is never present in any API response body', function () {
    [, $token] = registerAndCaptureVerificationToken();

    $response = $this->postJson('/api/v1/auth/email/verify', ['token' => $token]);

    expect(json_encode($response->json()))->not->toContain($token);
});

test('email verify does not require an access token (it is a public endpoint)', function () {
    [, $token] = registerAndCaptureVerificationToken();

    $this->postJson('/api/v1/auth/email/verify', ['token' => $token])->assertOk();
});

test('verifying email never exposes password_hash or the token hash in the response', function () {
    [, $token] = registerAndCaptureVerificationToken();

    $response = $this->postJson('/api/v1/auth/email/verify', ['token' => $token]);

    $user = $response->json('data.user');
    expect($user)->not->toHaveKey('password_hash');
    expect($user)->not->toHaveKey('token_hash');
});
