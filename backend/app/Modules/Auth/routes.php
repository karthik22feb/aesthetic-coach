<?php

use App\Modules\Auth\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Auth Module Routes
|--------------------------------------------------------------------------
|
| Registered by AuthServiceProvider (auto-discovered via ModuleServiceProvider,
| see docs/07-backend-architecture.md section 1). Only register/login/logout
| are implemented this session -- refresh, oauth, sessions, and password
| reset are deferred, per docs/05-api-specification.md section 3.
|
| Fail-closed by default: every route in this group requires a valid access
| token unless explicitly exempted below, per docs/14-production-hardening.md
| section 5 ("a forgotten annotation fails closed, not open"). Register and
| login are the only genuinely public actions here -- a new route added to
| this file without ->withoutMiddleware('auth:api') is protected by default,
| not accidentally public.
|
| All three routes carry the 'auth' rate limiter (10 req/min per IP), per
| docs/05-api-specification.md section 7.
|
*/

Route::middleware(['auth:api', 'throttle:auth'])->group(function () {
    Route::post('auth/register', [AuthController::class, 'register'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/login', [AuthController::class, 'login'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/logout', [AuthController::class, 'logout']);
});
