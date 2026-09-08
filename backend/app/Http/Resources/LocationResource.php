<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class LocationResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => (string) $this->id,
            'sector' => optional($this->sector)->name,
            'area' => $this->district,
            'landmark' => $this->address,
            'stores_count' => (int) ($this->stores_count ?? 0),
        ];
    }
}