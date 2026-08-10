<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Http\Requests\LoginRequest;
use App\Modules\Auth\Http\Requests\LogoutRequest;
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
