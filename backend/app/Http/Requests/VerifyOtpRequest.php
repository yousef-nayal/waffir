<?php
namespace App\Http\Requests;
class VerifyOtpRequest extends ApiRequest
{
    public function rules() { return ['phone'=>'required|string|max:30','code'=>'required|digits:6','name'=>'nullable|string|max:120','purpose'=>'sometimes|in:login,forgot_password']; }
    public function messages() { return ['phone.required'=>'رقم الجوال مطلوب.','code.required'=>'رمز التحقق مطلوب.','code.digits'=>'رمز التحقق يجب أن يتكون من 6 أرقام.']; }
}
