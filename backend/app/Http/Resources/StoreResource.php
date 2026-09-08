<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class StoreResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'address' => $this->address,
            'area' => optional($this->location)->district,
            'sector' => optional(optional($this->location)->sector)->name,
            'is_verified' => (bool) $this->is_verified,
            'prices_count' => (int) ($this->prices_count ?? 0),
        ];
    }
}