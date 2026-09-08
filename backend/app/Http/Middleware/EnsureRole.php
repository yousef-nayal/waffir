<?php

namespace App\Http\Middleware;

use Closure;

class EnsureRole
{
    public function handle($request, Closure $next, ...$roles)
    {
        $roles = array_map('intval', $roles);
        if (!$request->user() || !in_array((int) $request->user()->role, $roles, true)) {
            return response()->json(['success' => false, 'message' => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.'], 403);
        }
        return $next($request);
    }
}
