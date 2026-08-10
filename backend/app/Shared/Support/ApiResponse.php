<?php

namespace App\Shared\Support;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Builds the standard response envelope -- see docs/05-api-specification.md
 * section 4 (Error Response Format) and the apiVersion convention in section 1.
 */
class ApiResponse
{
    public static function success(mixed $data, int $status = 200, array $meta = []): JsonResponse
    {
        $body = ['data' => $data, 'apiVersion' => config('api.version')];

        if ($meta !== []) {
            $body['meta'] = $meta;
        }

        return response()->json($body, $status);
    }

    public static function error(string $code, string $message, int $status, ?array $details = null): JsonResponse
    {
        $error = ['code' => $code, 'message' => $message];

        if ($details !== null) {
            $error['details'] = $details;
        }

        $request = request();

        return response()->json([
            'error' => $error,
            'apiVersion' => config('api.version'),
            'requestId' => $request instanceof Request ? $request->attributes->get('requestId') : null,
        ], $status);
    }
}
