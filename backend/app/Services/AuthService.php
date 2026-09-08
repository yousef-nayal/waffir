<?php

namespace App\Services;

use App\Models\Otp;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthService
{
    public function requestOtp($identifier, $purpose = 'login')
    {
        $code = (string) random_int(100000, 999999);
        Otp::where('identifier', $identifier)->where('purpose', $purpose)
            ->whereNull('consumed_at')->update(['consumed_at' => now()]);
        Otp::create(['identifier' => $identifier, 'purpose' => $purpose,
            'code_hash' => Hash::make($code), 'expires_at' => now()->addMinutes(5)]);
        return $code;
    }

    public function verifyOtp($identifier, $code, $name = null, $purpose = 'login')
    {
        $otp = Otp::where('identifier', $identifier)->where('purpose', $purpose)
            ->whereNull('consumed_at')->where('expires_at', '>', now())->latest()->first();
        if (!$otp || $otp->attempts >= 5 || !Hash::check($code, $otp->code_hash)) {
            if ($otp) $otp->increment('attempts');
            throw ValidationException::withMessages(['otp' => ['رمز التحقق غير صحيح أو منتهي الصلاحية.']]);
        }
        $otp->update(['consumed_at' => now()]);
        $user = User::where('phone_number', $identifier)->orWhere('email', $identifier)->first();
        if (!$user) {
            $user = User::create(['phone_number' => $identifier,
                'email' => null,
                'name' => $name ?: 'مستخدم وفّر', 'password' => Hash::make(Str::random(40)),
                'role' => 0, 'is_active' => true]);
        }
        if (!$user->is_active) {
            throw ValidationException::withMessages(['phone_number' => ['حساب المستخدم غير مفعل.']]);
        }
        return [$user, $this->issueTokens($user)];
    }

    public function passwordLogin($identifier, $password)
    {
        $user = User::where('email', $identifier)->orWhere('phone_number', $identifier)->first();
        if (!$user || !$user->is_active || !Hash::check($password, $user->password)) {
            throw ValidationException::withMessages(['phone' => ['بيانات الدخول غير صحيحة.']]);
        }
        return [$user, $this->issueTokens($user)];
    }

    public function issueTokens(User $user)
    {
        JWTAuth::factory()->setTTL((int) config('jwt.ttl', 60));
        $access = JWTAuth::customClaims(['token_type' => 'access'])->fromUser($user);
        JWTAuth::factory()->setTTL((int) config('jwt.refresh_ttl', 20160));
        $refresh = JWTAuth::customClaims(['token_type' => 'refresh'])->fromUser($user);

        return [
            'access_token' => $access,
            'refresh_token' => $refresh,
            'token_type' => 'Bearer',
            'expires_in' => (int) config('jwt.ttl', 60) * 60,
        ];
    }

    public function revokeToken($token)
    {
        JWTAuth::setToken($token)->invalidate();
    }

    public function refresh($refreshToken)
    {
        $payload = JWTAuth::setToken($refreshToken)->getPayload();
        if ($payload->get('token_type') !== 'refresh') {
            throw ValidationException::withMessages(['refresh_token' => ['رمز التحديث غير صالح.']]);
        }

        $user = User::find($payload->get('sub'));
        if (!$user || !$user->is_active) {
            throw ValidationException::withMessages(['refresh_token' => ['جلسة المستخدم غير صالحة.']]);
        }

        JWTAuth::setToken($refreshToken)->invalidate();
        return $this->issueTokens($user);
    }
}
