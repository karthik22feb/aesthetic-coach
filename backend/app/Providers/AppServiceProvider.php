<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // General API limiter, per docs/05-api-specification.md section 7
        // ("General API (per user): 120 req/min") -- registered centrally
        // (not inside a single module's ServiceProvider) since it's meant
        // to apply across every authenticated endpoint, not just Auth's.
        // Falls back to per-IP for the (currently theoretical) case of an
        // authenticated route reached without a resolved user.
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(120)->by($request->user()?->id ?: $request->ip());
        });
    }
}
