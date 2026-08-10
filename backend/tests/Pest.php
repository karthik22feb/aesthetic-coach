<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
|
| Feature tests run against real MySQL (not SQLite-in-memory), per
| docs/10-testing-strategy.md section 5 -- RefreshDatabase wraps each test
| in a transaction and rolls back after, using the ephemeral schema in
| aesthetic_coach_test (see phpunit.xml).
|
*/

/*
|--------------------------------------------------------------------------
| Rate Limiter Isolation
|--------------------------------------------------------------------------
|
| The test cache driver (array, see phpunit.xml) is an in-process store that
| is NOT reset between test methods the way RefreshDatabase resets the DB --
| without this, the 'auth' rate limiter's per-IP counters accumulate across
| every test in the run, causing unrelated tests to fail with 429 once the
| shared bucket is exhausted. Flushing before each test keeps rate-limiting
| itself genuinely exercised (RateLimitTest.php still hits real 429s) while
| giving every other test a clean slate.
|
*/

pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->beforeEach(function () {
        Cache::flush();
    })
    ->in('Feature');

/*
|--------------------------------------------------------------------------
| Expectations
|--------------------------------------------------------------------------
|
| When you're writing tests, you often need to check that values meet certain conditions. The
| "expect()" function gives you access to a set of "expectations" methods that you can use
| to assert different things. Of course, you may extend the Expectation API at any time.
|
*/

expect()->extend('toBeOne', function () {
    return $this->toBe(1);
});

/*
|--------------------------------------------------------------------------
| Functions
|--------------------------------------------------------------------------
|
| While Pest is very powerful out-of-the-box, you may have some testing code specific to your
| project that you don't want to repeat in every file. Here you can also expose helpers as
| global functions to help you to reduce the number of lines of code in your test files.
|
*/

/**
 * A minimal valid /auth/register payload, per docs/features/authentication.md
 * Validation Rules and BR-1 (password policy).
 */
function validRegistrationPayload(array $overrides = []): array
{
    return array_merge([
        'name' => 'Priya Shah',
        'email' => 'priya@example.com',
        'password' => 'correct-horse-battery1',
        'platform' => 'ios',
        'deviceName' => 'iPhone 15',
    ], $overrides);
}
