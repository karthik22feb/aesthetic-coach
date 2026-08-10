<?php

namespace App\Shared\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

/**
 * Generates/propagates a request ID so every response (success or error) can
 * be correlated with server logs -- see docs/13-monitoring-logging.md section 1.
 */
class RequestIdMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $requestId = $request->header('X-Request-Id') ?: 'req_'.(string) Str::ulid();

        $request->attributes->set('requestId', $requestId);

        $response = $next($request);
        $response->headers->set('X-Request-Id', $requestId);

        return $response;
    }
}
