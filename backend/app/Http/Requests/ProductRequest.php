<?php
namespace App\Http\Requests;
class ProductRequest extends ApiRequest
{
    public function rules() { return ['name'=>'required|string|max:255','category'=>'required|string|max:255','unit'=>'nullable|string|max:120','default_unit_id'=>'nullable|exists:units,id']; }
}
