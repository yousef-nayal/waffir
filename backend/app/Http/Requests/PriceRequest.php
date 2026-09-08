<?php
namespace App\Http\Requests;
class PriceRequest extends ApiRequest
{
    public function rules() { return ['store_id'=>'required|exists:stores,id','product_id'=>'required|exists:products,id','unit'=>'required|string|max:120','brand'=>'nullable|string|max:120','quantity'=>'required|numeric|gt:0','price'=>'required|numeric|min:0']; }
}
