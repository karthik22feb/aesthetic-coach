<?php

use App\Modules\Auth\Http\Controllers\AuthController;
use App\Modules\Auth\Http\Controllers\SessionController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Auth Module Routes
|--------------------------------------------------------------------------
|
| Registered by AuthServiceProvider (auto-discovered via ModuleServiceProvider,
| see docs/07-backend-architecture.md, section 1). Register, login, oauth,
| refresh, logout, and session/device management are implemented -- email
| verification and password reset are deferred, per
| docs/05-api-specification.md section 3.
|
| Fail-closed by default: every route in this group requires a valid access
| token unless explicitly exempted below, per docs/14-production-hardening.md
| section 5 ("a forgotten annotation fails closed, not open"). Register,
| login, oauth, and refresh are public (each is itself a way to establish a
| session, so none can require one already exists) -- everything else
| defaults to protected.
|
| All routes carry the 'auth' rate limiter (10 req/min per IP), per
| docs/05-api-specification.md section 7.
|
*/

Route::middleware(['auth:api', 'throttle:auth'])->group(function () {
    Route::post('auth/register', [AuthController::class, 'register'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/login', [AuthController::class, 'login'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/oauth/google', [AuthController::class, 'oauthGoogle'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/oauth/apple', [AuthController::class, 'oauthApple'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/refresh', [AuthController::class, 'refresh'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/logout', [AuthController::class, 'logout']);

    Route::get('auth/sessions', [SessionController::class, 'index']);

    Route::delete('auth/sessions/{deviceId}', [SessionController::class, 'destroy'])
        ->whereNumber('deviceId');
});
