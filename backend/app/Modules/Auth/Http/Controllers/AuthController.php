<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Enums\OAuthProvider;
use App\Modules\Auth\Http\Requests\LoginRequest;
use App\Modules\Auth\Http\Requests\LogoutRequest;
use App\Modules\Auth\Http\Requests\OAuthLoginRequest;
use App\Modules\Auth\Http\Requests\RefreshRequest;
use App\Modules\Auth\Http\Requests\RegisterRequest;
use App\Modules\Auth\Http\Resources\UserResource;
use App\Modules\Auth\Models\User;
use App\Modules\Auth\Services\AuthService;
use App\Shared\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
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
