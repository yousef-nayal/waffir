<?php
namespace App\Http\Resources;
use Illuminate\Http\Resources\Json\JsonResource;
class BasicResource extends JsonResource
{
    public function toArray($request)
    {
        $data = ['id' => (string) $this->id, 'name' => $this->name];
        if ($this->getTable() === 'brands') $data['products_count'] = (int) ($this->products_count ?? 0);
        if ($this->getTable() === 'units') $data['usage_count'] = (int) ($this->usage_count ?? 0);
        if ($this->getTable() === 'sectors') $data['description'] = $this->description;
        return $data;
    }
}
