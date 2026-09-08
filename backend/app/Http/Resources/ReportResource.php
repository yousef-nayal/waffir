<?php
namespace App\Http\Resources;
use Illuminate\Http\Resources\Json\JsonResource;
class ReportResource extends JsonResource
{
    public function toArray($request) { return ['id'=>(string)$this->id,'price_entry_id'=>(string)$this->price_id,'product_name'=>optional(optional($this->price)->product)->name,'store_name'=>optional(optional($this->price)->store)->name,'store_area'=>optional(optional(optional($this->price)->store)->location)->district,'user_name'=>optional($this->user)->name,'type'=>$this->type,'note'=>$this->description,'reported_at'=>optional($this->created_at)->toISOString(),'status'=>$this->status]; }
}
