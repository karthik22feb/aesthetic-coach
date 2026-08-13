<?php

namespace App\Modules\Auth;

use App\Modules\Auth\Contracts\JwksProvider;
use App\Modules\Auth\Events\UserRegistered;
use App\Modules\Auth\Listeners\SendVerificationEmail;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\HttpJwksProvider;
use App\Modules\Auth\Services\TokenService;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Throwable;

/**
 * Auto-discovered by App\Providers\ModuleServiceProvider. Registers the
 * custom stateless JWT guard (ADR-0005), the auth-endpoint rate limiter,
 * and this module's own routes.
 */
class AuthServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bound as a singleton so a single request only ever holds one
        // in-memory reference; the actual JWKS caching is handled by
        // HttpJwksProvider itself via the application cache store (Redis),
        // not by this container scope.
        $this->app->singleton(JwksProvider::class, HttpJwksProvider::class);
    }

    public function boot(): void
    {
        Auth::viaRequest('jwt', function (Request $request) {
            $token = $request->bearerToken();

            if ($token === null) {
                return null;
            }

            try {
                $payload = $this->app->make(TokenService::class)->validateAccessToken($token);
            } catch (Throwable) {
                return null;
            }

            $user = User::find($payload->sub);

            // A transient, non-persisted attribute (never saved back to the
            // database) so GET /auth/sessions can compute isCurrent from the
            // token's 'did' claim without a second lookup -- see
            // TokenService::issueAccessToken().
            if ($user !== null) {
                $user->currentDeviceId = isset($payload->did) ? (int) $payload->did : null;
            }

            return $user;
        });

        // 10 req/min per IP, per docs/05-api-specification.md section 7.
        RateLimiter::for('auth', fn (Request $request) => Limit::perMinute(10)->by($request->ip()));

        // Wires FR-101's acceptance criteria ("account is created and
        // verification email sent") -- see UserRegistered's docblock and
        // SendVerificationEmail.
        Event::listen(UserRegistered::class, SendVerificationEmail::class);

        Route::middleware('api')->prefix('api/v1')->group(function () {
            require __DIR__.'/routes.php';
        });
    }
}
