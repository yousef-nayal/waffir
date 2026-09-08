<?php

namespace App\Http\Middleware;

use Closure;

class EnsureUserIsActive
{
    public function handle($request, Closure $next)
    {
        if (!$request->user() || !$request->user()->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'حساب المستخدم غير مفعل.',
            ], 403);
        }
        return $next($request);
    }
}
