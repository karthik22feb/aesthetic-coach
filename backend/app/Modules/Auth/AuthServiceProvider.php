<?php

namespace App\Modules\Auth;

use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\TokenService;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
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

            return User::find($payload->sub);
        });

        // 10 req/min per IP, per docs/05-api-specification.md section 7.
        RateLimiter::for('auth', fn (Request $request) => Limit::perMinute(10)->by($request->ip()));

        Route::middleware('api')->prefix('api/v1')->group(function () {
            require __DIR__.'/routes.php';
        });
    }
}
