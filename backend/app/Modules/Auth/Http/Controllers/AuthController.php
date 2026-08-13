<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Enums\OAuthProvider;
use App\Modules\Auth\Http\Requests\ForgotPasswordRequest;
use App\Modules\Auth\Http\Requests\LoginRequest;
use App\Modules\Auth\Http\Requests\LogoutRequest;
use App\Modules\Auth\Http\Requests\OAuthLoginRequest;
use App\Modules\Auth\Http\Requests\RefreshRequest;
use App\Modules\Auth\Http\Requests\RegisterRequest;
use App\Modules\Auth\Http\Requests\ResetPasswordRequest;
use App\Modules\Auth\Http\Requests\VerifyEmailRequest;
use App\Modules\Auth\Http\Resources\UserResource;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\AuthService;
use App\Shared\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class AuthController extends Controller
{
    public function __construct(protected AuthService $authService) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $session = $this->authService->register($request->toDto());

        return $this->sessionResponse($session, 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $session = $this->authService->login($request->toDto());

        return $this->sessionResponse($session, 200);
    }

    public function oauthGoogle(OAuthLoginRequest $request): JsonResponse
    {
        return $this->oauthLogin(OAuthProvider::Google, $request);
    }

    public function oauthApple(OAuthLoginRequest $request): JsonResponse
    {
        return $this->oauthLogin(OAuthProvider::Apple, $request);
    }

    protected function oauthLogin(OAuthProvider $provider, OAuthLoginRequest $request): JsonResponse
    {
        $session = $this->authService->oauthLogin(
            $provider,
            $request->string('idToken')->toString(),
            $request->platform(),
            $request->deviceName(),
        );

        // 201 only when this call actually created the account (mirrors
        // register()'s 201 vs login()'s 200) -- an existing user signing in
        // via an already-linked or newly-linked provider identity gets 200.
        return $this->sessionResponse($session, $session['created'] ? 201 : 200);
    }

    public function refresh(RefreshRequest $request): JsonResponse
    {
        $session = $this->authService->refresh($request->string('refreshToken')->toString());

        return ApiResponse::success([
            'accessToken' => $session['accessToken'],
            'refreshToken' => $session['refreshToken'],
            'expiresIn' => $session['expiresIn'],
        ], 200);
    }

    public function logout(LogoutRequest $request): Response
    {
        $this->authService->logout($request->user(), $request->string('refreshToken')->toString());

        return response()->noContent();
    }

    /**
     * Always returns the same generic response whether or not the email
     * matches an account -- see ForgotPasswordRequest's docblock and
     * AuthService::forgotPassword() for the anti-enumeration reasoning.
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $this->authService->forgotPassword($request->string('email')->toString());

        return ApiResponse::success([
            'message' => 'If an account exists for this email, a password reset link has been sent.',
        ], 200);
    }

    public function resetPassword(ResetPasswordRequest $request): Response
    {
        $this->authService->resetPassword(
            $request->string('token')->toString(),
            $request->string('password')->toString(),
        );

        // No new session is issued -- every session was just revoked, so
        // the client must log in again.
        return response()->noContent();
    }

    public function verifyEmail(VerifyEmailRequest $request): JsonResponse
    {
        $user = $this->authService->verifyEmail($request->string('token')->toString());

        return ApiResponse::success(['user' => new UserResource($user)], 200);
    }

    public function resendVerification(Request $request): Response
    {
        $this->authService->sendVerificationEmail($request->user());

        return response()->noContent();
    }

    /**
     * @param  array{user: User, accessToken: string, refreshToken: string, expiresIn: int}  $session
     */
    protected function sessionResponse(array $session, int $status): JsonResponse
    {
        return ApiResponse::success([
            'user' => new UserResource($session['user']),
            'accessToken' => $session['accessToken'],
            'refreshToken' => $session['refreshToken'],
            'expiresIn' => $session['expiresIn'],
        ], $status);
    }
}
