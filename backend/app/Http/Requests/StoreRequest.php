<?php
namespace App\Http\Requests;
class StoreRequest extends ApiRequest
{
    public function rules() { return ['name'=>'required|string|max:255','address'=>'required|string|max:500','area'=>'required|string|max:255','sector'=>'required|string|max:255','phone'=>'nullable|string|max:30','logo_url'=>'nullable|url|max:2048']; }
}
