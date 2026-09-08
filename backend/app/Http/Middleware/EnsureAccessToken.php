<?php

namespace App\Http\Middleware;

use Closure;
use Tymon\JWTAuth\Facades\JWTAuth;

class EnsureAccessToken
{
    public function handle($request, Closure $next)
    {
        $payload = JWTAuth::parseToken()->getPayload();

        if ($payload->get('token_type') !== 'access') {
            return response()->json([
                'success' => false,
                'message' => 'نوع رمز الدخول غير صالح.',
            ], 401);
        }

        return $next($request);
    }
}