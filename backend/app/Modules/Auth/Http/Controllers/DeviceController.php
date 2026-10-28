<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Http\Requests\RegisterDeviceRequest;
use App\Modules\Auth\Services\AuthService;
use Illuminate\Http\Response;

class DeviceController extends Controller
{
    public function __construct(protected AuthService $authService) {}

    /**
     * No response body on success -- the caller already has the token it
     * just sent; nothing new to echo back, same reasoning as logout() and
     * SessionController::destroy()'s 204s.
     */
    public function store(RegisterDeviceRequest $request): Response
    {
        $this->authService->registerPushToken(
            $request->user(),
            $request->string('pushToken')->toString(),
        );

        return response()->noContent();
    }
}
