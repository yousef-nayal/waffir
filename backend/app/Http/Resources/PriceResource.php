<?php
namespace App\Http\Resources;
use Illuminate\Http\Resources\Json\JsonResource;
class PriceResource extends JsonResource
{
    public function toArray($request) { $ratings=$this->relationLoaded('ratings')?$this->ratings:collect(); return ['id'=>(string)$this->id,'product_id'=>(string)$this->product_id,'product_name'=>optional($this->product)->name,'store_id'=>(string)$this->store_id,'store_name'=>optional($this->store)->name,'store_area'=>optional(optional($this->store)->location)->district,'price'=>(float)$this->price,'unit'=>optional($this->unit)->name,'quantity'=>(float)$this->amount,'brand'=>optional($this->brand)->name,'submitted_by'=>optional($this->user)->name,'submitted_at'=>optional($this->created_at)->toISOString(),'thumbs_up'=>$ratings->where('value',true)->count(),'thumbs_down'=>$ratings->where('value',false)->count(),'total_ratings'=>$ratings->count(),'status'=>$this->status]; }
}
