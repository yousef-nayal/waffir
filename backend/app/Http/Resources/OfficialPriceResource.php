<?php
namespace App\Http\Resources;
use Illuminate\Http\Resources\Json\JsonResource;
class OfficialPriceResource extends JsonResource
{
    public function toArray($request) { return ['id'=>(string)$this->id,'product_name'=>optional($this->product)->name,'unit'=>optional($this->unit)->name,'quantity'=>(float)$this->amount,'price'=>(float)$this->price,'updated_at'=>optional($this->updated_at)->toISOString()]; }
}
