<?php
namespace App\Http\Requests;
class RatingRequest extends ApiRequest
{
    public function rules() { return ['price_id'=>'required|exists:prices,id','value'=>'required|boolean']; }
}
