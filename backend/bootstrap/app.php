<?php

use App\Shared\Http\Middleware\ForceJsonResponse;
use App\Shared\Http\Middleware\RequestIdMiddleware;
use App\Shared\Support\ApiResponse;
use App\Shared\Support\AppException;
use Carbon\CarbonImmutable;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api_v1.php',
        apiPrefix: 'api/v1',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->append(RequestIdMiddleware::class);
        $middleware->append(ForceJsonResponse::class);

        // Throttle state is tracked via the configured cache store
        // (CACHE_STORE=redis in dev/production), so limits hold across the
        // horizontally-scaled app tier -- see docs/14-production-hardening.md
        // section 2. Deliberately NOT using throttleWithRedis(): that variant
        // talks to Redis directly regardless of CACHE_STORE, which breaks
        // test-environment isolation (CACHE_STORE=array in phpunit.xml).
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        $exceptions->render(function (AppException $e, Request $request) {
            if ($request->is('api/*')) {
                return ApiResponse::error($e->errorCode(), $e->getMessage(), $e->status(), $e->details());
            }
        });

        $exceptions->render(function (ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return ApiResponse::error('validation_failed', 'The given data was invalid.', 422, $e->errors());
            }
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return ApiResponse::error('unauthenticated', 'Your session has expired. Please log in again.', 401);
            }
        });

        $exceptions->render(function (ThrottleRequestsException $e, Request $request) {
            if ($request->is('api/*')) {
                $headers = $e->getHeaders();
                $details = isset($headers['X-RateLimit-Reset'])
                    ? ['resetAt' => CarbonImmutable::createFromTimestamp((int) $headers['X-RateLimit-Reset'])->toIso8601String()]
                    : null;

                return ApiResponse::error('rate_limited', 'Too many requests. Please try again later.', 429, $details)
                    ->withHeaders($headers);
            }
        });
    })->create();
