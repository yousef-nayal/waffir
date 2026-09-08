<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    protected $auth;

    public function __construct(AuthService $auth)
    {
        $this->auth = $auth;
    }

    public function register(RegisterRequest $request)
    {
        list($user, $tokens) = $this->auth->register($request->validated());
        return response()->json(['success' => true, 'message' => 'تم إنشاء الحساب بنجاح.', 'data' => [
            'user' => new UserResource($user), 'tokens' => $tokens,
        ]], 201);
    }

    public function login(LoginRequest $request)
    {
        list($user, $tokens) = $this->auth->login($request->validated());
        return response()->json(['success' => true, 'message' => 'تم تسجيل الدخول بنجاح.', 'data' => [
            'user' => new UserResource($user), 'tokens' => $tokens,
        ]]);
    }

    public function me(Request $request)
    {
        return response()->json(['success' => true, 'data' => new UserResource($request->user())]);
    }

    public function logout(Request $request)
    {
        $this->auth->revokeCurrent($request->user());
        return response()->json(['success' => true, 'message' => 'تم تسجيل الخروج بنجاح.']);
    }

    public function refresh(Request $request)
    {
        $this->auth->revokeCurrent($request->user());
        $tokens = $this->auth->issue($request->user(), $request->input('device_name', 'api'));
        return response()->json(['success' => true, 'message' => 'تم تحديث رمز الدخول.', 'data' => ['tokens' => $tokens]]);
    }
}
