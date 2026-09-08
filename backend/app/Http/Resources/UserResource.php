<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request)
    {
        return ['id'=>(string)$this->id,'name'=>$this->name,'phone'=>$this->phone_number,
            'location'=>optional($this->location)->district,'prices_count'=>(int)($this->prices_count ?? 0),'ratings_count'=>(int)($this->ratings_count ?? 0),'reports_count'=>(int)($this->reports_count ?? 0),'role'=>$this->isAdmin()?'admin':'user','is_active'=>(bool)$this->is_active,'created_at'=>optional($this->created_at)->toISOString()];
    }
}
