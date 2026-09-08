<?php
namespace App\Http\Resources;
use Illuminate\Http\Resources\Json\JsonResource;
class ProductResource extends JsonResource
{
    public function toArray($request) {
        $official = $this->officialPrices->sortByDesc('updated_at')->first();
        $approved = $this->prices->where('status', 'approved');
        $real = $approved->avg('price');
        $officialPrice = $official ? (float)$official->price : null;
        $change = $officialPrice && $real !== null ? (($real - $officialPrice) / $officialPrice) * 100 : null;
        return ['id'=>$this->id,'name'=>$this->name,'category'=>$this->category,
            'official_price'=>$officialPrice,
            'real_price'=>$real !== null ? (float)$real : null,
            'avg_price'=>$real !== null ? (float)$real : null,
            'unit'=>optional($this->defaultUnit)->name ?: optional($official ? $official->unit : null)->name,
            'prices_count'=>$approved->count(),'change_percent'=>$change !== null ? (float)$change : null,
            'is_price_up'=>$change !== null ? $change > 0 : false];
    }
}
