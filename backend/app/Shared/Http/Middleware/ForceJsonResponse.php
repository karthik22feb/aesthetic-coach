<?php

namespace App\Shared\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Forces every API request to be treated as JSON-expecting, so framework-level
 * failures (e.g. the auth guard's default redirect-to-login behavior on an
 * unauthenticated request) render through the JSON error envelope instead of
 * attempting a web-app redirect that doesn't exist in this API-only app --
 * see docs/07-backend-architecture.md section 3.
 */
class ForceJsonResponse
{
    public function handle(Request $request, Closure $next): Response
    {
        $request->headers->set('Accept', 'application/json');

        return $next($request);
    }
}
