<?php
namespace App\Http\Requests;
class ReportRequest extends ApiRequest
{
    public function rules() { return ['price_entry_id'=>'required|exists:prices,id','type'=>'required|in:wrong_price,outdated,duplicate,other','note'=>'nullable|string|max:5000']; }
}
