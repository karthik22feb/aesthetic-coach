<?php

use App\Modules\Auth\Http\Controllers\AuthController;
use App\Modules\Auth\Http\Controllers\ProfileController;
use App\Modules\Auth\Http\Controllers\SessionController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Auth Module Routes
|--------------------------------------------------------------------------
|
| Registered by AuthServiceProvider (auto-discovered via ModuleServiceProvider,
| see docs/07-backend-architecture.md, section 1). Register, login, oauth,
| refresh, logout, session/device management, email verification, and
| password reset are all implemented, per docs/05-api-specification.md
| section 3.
|
| Fail-closed by default: every route in this group requires a valid access
| token unless explicitly exempted below, per docs/14-production-hardening.md
| section 5 ("a forgotten annotation fails closed, not open"). Register,
| login, oauth, refresh, password/forgot, password/reset, and email/verify
| are public (each either establishes a session or is itself the credential
| for a pre-authentication action) -- everything else defaults to protected,
| including email/resend (only a logged-in user needs to re-request their
| own verification email).
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

    Route::post('auth/password/forgot', [AuthController::class, 'forgotPassword'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/password/reset', [AuthController::class, 'resetPassword'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/email/verify', [AuthController::class, 'verifyEmail'])
        ->withoutMiddleware('auth:api');

    Route::post('auth/email/resend', [AuthController::class, 'resendVerification']);

    Route::get('auth/sessions', [SessionController::class, 'index']);

    Route::delete('auth/sessions/{deviceId}', [SessionController::class, 'destroy'])
        ->whereNumber('deviceId');
});

/*
|--------------------------------------------------------------------------
| Profile Routes -- Sprint 2, Task 1 (docs/TASK_BREAKDOWN.md)
|--------------------------------------------------------------------------
|
| GET/PATCH /me only -- DELETE /me and POST /me/export (also documented
| under docs/api-examples/users-profile.md) belong to later tasks (account
| deletion / data export, FR-108) and are deliberately not implemented
| here.
|
| Uses the general 'api' limiter (120 req/min per user, docs/05-api-
| specification.md section 7), not the 10/min 'auth' limiter above --
| that one is scoped to brute-force-prone auth endpoints (register/login/
| refresh/password-reset), not general authenticated API traffic.
|
*/
Route::middleware(['auth:api', 'throttle:api'])->group(function () {
    Route::get('me', [ProfileController::class, 'show']);
    Route::patch('me', [ProfileController::class, 'update']);
});
