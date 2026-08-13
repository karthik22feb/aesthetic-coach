<?php

use App\Modules\Auth\Contracts\JwksProvider;
use App\Modules\Auth\Exceptions\InvalidOAuthTokenException;
use App\Modules\Auth\Services\AppleIdTokenVerifier;
use App\Modules\Auth\Services\GoogleIdTokenVerifier;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

/*
|--------------------------------------------------------------------------
| Verifier abstraction tests
|--------------------------------------------------------------------------
|
| Exercises the REAL signature/issuer/audience/expiration verification logic
| in AbstractOAuthIdTokenVerifier -- no network call, no mocking of the
| verifier itself. A local RSA keypair stands in for "the provider's"
| signing key, injected via a fake JwksProvider bound in the container, so
| every check (signature, issuer, audience, expiry, required claims) is
| exercised against real cryptography, deterministically. Feature-level
| flow tests (OAuthGoogleTest/OAuthAppleTest) mock the verifier itself
| instead, per this session's testing brief.
|
*/

function makeRsaKeyPair(): array
{
    $resource = openssl_pkey_new([
        'private_key_bits' => 2048,
        'private_key_type' => OPENSSL_KEYTYPE_RSA,
    ]);
    openssl_pkey_export($resource, $privateKey);
    $publicKey = openssl_pkey_get_details($resource)['key'];

    return [$privateKey, $publicKey];
}

function bindFakeGoogleJwks(string $publicKeyPem, string $kid = 'test-kid'): void
{
    config([
        'oauth.google.client_id' => 'test-google-client-id',
        'oauth.google.issuers' => ['https://accounts.google.com', 'accounts.google.com'],
    ]);

    app()->instance(JwksProvider::class, new class($kid, $publicKeyPem) implements JwksProvider
    {
        public function __construct(private string $kid, private string $publicKeyPem) {}

        public function keySet(string $jwksUrl): array
        {
            return [$this->kid => new Key($this->publicKeyPem, 'RS256')];
        }
    });
}

test('a validly signed Google token with correct claims is accepted', function () {
    [$privateKey, $publicKey] = makeRsaKeyPair();
    bindFakeGoogleJwks($publicKey);

    $token = JWT::encode([
        'iss' => 'https://accounts.google.com',
        'aud' => 'test-google-client-id',
        'sub' => 'google-user-123',
        'email' => 'priya@example.com',
        'email_verified' => true,
        'name' => 'Priya Shah',
        'iat' => time(),
        'exp' => time() + 300,
    ], $privateKey, 'RS256', 'test-kid');

    $claims = app(GoogleIdTokenVerifier::class)->verify($token);

    expect($claims->providerUserId)->toBe('google-user-123');
    expect($claims->email)->toBe('priya@example.com');
    expect($claims->emailVerified)->toBeTrue();
    expect($claims->name)->toBe('Priya Shah');
});

test('a token signed by a different key than the provider published is rejected', function () {
    [, $publicKey] = makeRsaKeyPair();
    [$attackerPrivateKey] = makeRsaKeyPair();
    bindFakeGoogleJwks($publicKey);

    $token = JWT::encode([
        'iss' => 'https://accounts.google.com',
        'aud' => 'test-google-client-id',
        'sub' => 'google-user-123',
        'email' => 'priya@example.com',
        'email_verified' => true,
        'iat' => time(),
        'exp' => time() + 300,
    ], $attackerPrivateKey, 'RS256', 'test-kid');

    app(GoogleIdTokenVerifier::class)->verify($token);
})->throws(InvalidOAuthTokenException::class);

test('an expired Google token is rejected', function () {
    [$privateKey, $publicKey] = makeRsaKeyPair();
    bindFakeGoogleJwks($publicKey);

    $token = JWT::encode([
        'iss' => 'https://accounts.google.com',
        'aud' => 'test-google-client-id',
        'sub' => 'google-user-123',
        'email' => 'priya@example.com',
        'email_verified' => true,
        'iat' => time() - 600,
        'exp' => time() - 300,
    ], $privateKey, 'RS256', 'test-kid');

    app(GoogleIdTokenVerifier::class)->verify($token);
})->throws(InvalidOAuthTokenException::class);

test('a Google token with the wrong issuer is rejected', function () {
    [$privateKey, $publicKey] = makeRsaKeyPair();
    bindFakeGoogleJwks($publicKey);

    $token = JWT::encode([
        'iss' => 'https://evil.example.com',
        'aud' => 'test-google-client-id',
        'sub' => 'google-user-123',
        'email' => 'priya@example.com',
        'email_verified' => true,
        'iat' => time(),
        'exp' => time() + 300,
    ], $privateKey, 'RS256', 'test-kid');

    app(GoogleIdTokenVerifier::class)->verify($token);
})->throws(InvalidOAuthTokenException::class);

test('a Google token with the wrong audience is rejected', function () {
    [$privateKey, $publicKey] = makeRsaKeyPair();
    bindFakeGoogleJwks($publicKey);

    $token = JWT::encode([
        'iss' => 'https://accounts.google.com',
        'aud' => 'someone-elses-client-id',
        'sub' => 'google-user-123',
        'email' => 'priya@example.com',
        'email_verified' => true,
        'iat' => time(),
        'exp' => time() + 300,
    ], $privateKey, 'RS256', 'test-kid');

    app(GoogleIdTokenVerifier::class)->verify($token);
})->throws(InvalidOAuthTokenException::class);

test('a malformed token string is rejected', function () {
    [, $publicKey] = makeRsaKeyPair();
    bindFakeGoogleJwks($publicKey);

    app(GoogleIdTokenVerifier::class)->verify('not-a-jwt-at-all');
})->throws(InvalidOAuthTokenException::class);

test('a Google token missing the email claim is rejected', function () {
    [$privateKey, $publicKey] = makeRsaKeyPair();
    bindFakeGoogleJwks($publicKey);

    $token = JWT::encode([
        'iss' => 'https://accounts.google.com',
        'aud' => 'test-google-client-id',
        'sub' => 'google-user-123',
        'iat' => time(),
        'exp' => time() + 300,
    ], $privateKey, 'RS256', 'test-kid');

    app(GoogleIdTokenVerifier::class)->verify($token);
})->throws(InvalidOAuthTokenException::class);

test('Apple email_verified sent as the string "true" is normalized to a real boolean', function () {
    [$privateKey, $publicKey] = makeRsaKeyPair();
    config([
        'oauth.apple.client_id' => 'com.aestheticcoach.app',
        'oauth.apple.issuers' => ['https://appleid.apple.com'],
    ]);
    app()->instance(JwksProvider::class, new class($publicKey) implements JwksProvider
    {
        public function __construct(private string $publicKeyPem) {}

        public function keySet(string $jwksUrl): array
        {
            return ['apple-kid' => new Key($this->publicKeyPem, 'RS256')];
        }
    });

    // Apple's real ID tokens encode this claim as a JSON string, not a
    // boolean -- a documented quirk this verifier must handle explicitly.
    $token = JWT::encode([
        'iss' => 'https://appleid.apple.com',
        'aud' => 'com.aestheticcoach.app',
        'sub' => 'apple-user-456',
        'email' => 'priya@privaterelay.appleid.com',
        'email_verified' => 'true',
        'iat' => time(),
        'exp' => time() + 300,
    ], $privateKey, 'RS256', 'apple-kid');

    $claims = app(AppleIdTokenVerifier::class)->verify($token);

    expect($claims->emailVerified)->toBeTrue();
    expect($claims->name)->toBeNull();
});

test('Apple email_verified sent as the string "false" is normalized correctly', function () {
    [$privateKey, $publicKey] = makeRsaKeyPair();
    config([
        'oauth.apple.client_id' => 'com.aestheticcoach.app',
        'oauth.apple.issuers' => ['https://appleid.apple.com'],
    ]);
    app()->instance(JwksProvider::class, new class($publicKey) implements JwksProvider
    {
        public function __construct(private string $publicKeyPem) {}

        public function keySet(string $jwksUrl): array
        {
            return ['apple-kid' => new Key($this->publicKeyPem, 'RS256')];
        }
    });

    $token = JWT::encode([
        'iss' => 'https://appleid.apple.com',
        'aud' => 'com.aestheticcoach.app',
        'sub' => 'apple-user-456',
        'email' => 'priya@example.com',
        'email_verified' => 'false',
        'iat' => time(),
        'exp' => time() + 300,
    ], $privateKey, 'RS256', 'apple-kid');

    $claims = app(AppleIdTokenVerifier::class)->verify($token);

    expect($claims->emailVerified)->toBeFalse();
});
