<?php
namespace App\Http\Resources;
use Illuminate\Http\Resources\Json\JsonResource;
class RatingResource extends JsonResource
{
    public function toArray($request) { return ['id'=>$this->id,'price_id'=>$this->price_id,'user_id'=>$this->user_id,'value'=>(bool)$this->value]; }
}
