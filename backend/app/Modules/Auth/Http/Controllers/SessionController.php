<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Http\Resources\SessionResource;
use App\Modules\Auth\Services\AuthService;
use App\Shared\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class SessionController extends Controller
{
    public function __construct(protected AuthService $authService) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $currentDeviceId = $user->currentDeviceId ?? null;

        $sessions = $this->authService->listSessions($user)
            ->map(fn ($device) => new SessionResource($device, $currentDeviceId));

        return ApiResponse::success($sessions);
    }

    public function destroy(Request $request, int $deviceId): Response
    {
        $this->authService->revokeSession($request->user(), $deviceId);

        return response()->noContent();
    }
}
