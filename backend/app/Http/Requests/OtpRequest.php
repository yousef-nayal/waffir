<?php
namespace App\Http\Requests;
class OtpRequest extends ApiRequest
{
    public function rules() { return ['phone' => 'required|string|max:30','purpose'=>'sometimes|in:login,forgot_password']; }
    public function messages() { return ['phone.required' => 'رقم الجوال مطلوب.']; }
}
