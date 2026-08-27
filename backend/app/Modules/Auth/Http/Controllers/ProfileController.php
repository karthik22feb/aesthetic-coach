<?php

namespace App\Modules\Auth\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Http\Requests\UpdateProfileRequest;
use App\Modules\Auth\Http\Resources\ProfileResource;
use App\Modules\Auth\Services\ProfileService;
use App\Shared\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function __construct(protected ProfileService $profileService) {}

    public function show(Request $request): JsonResponse
    {
        return ApiResponse::success(new ProfileResource($request->user()), 200);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $this->profileService->updateProfile($request->user(), $request->toDto()->attributes);

        return ApiResponse::success(new ProfileResource($user), 200);
    }
}
