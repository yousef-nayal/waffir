<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Resources\OfficialPriceResource;
use App\Models\OfficialPrice;
use App\Models\OfficialPriceHistory;
use App\Models\Product;
use App\Models\Unit;
use Illuminate\Validation\ValidationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
class OfficialPriceController extends Controller
{
    public function index(Request $request) { $items=OfficialPrice::with(['product','unit'])->when($request->search,function($q,$v){return $q->whereHas('product',function($p)use($v){$p->where('name','like','%'.$v.'%');});})->when($request->product_id,function($q,$v){return $q->where('product_id',$v);})->latest()->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>OfficialPriceResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function show(OfficialPrice $officialPrice) { return response()->json(['success'=>true,'data'=>new OfficialPriceResource($officialPrice)]); }
    public function store(Request $request) { $data=$this->validateData($request); $item=DB::transaction(function()use($data,$request){$item=OfficialPrice::updateOrCreate(['product_id'=>$data['product_id'],'unit_id'=>$data['unit_id'],'amount'=>$data['amount']],['price'=>$data['price']]); OfficialPriceHistory::create(['official_price_id'=>$item->id,'product_id'=>$item->product_id,'unit_id'=>$item->unit_id,'amount'=>$item->amount,'price'=>$item->price,'new_price'=>$item->price,'changed_by'=>$request->user()->id,'changed_at'=>now()]); return $item;}); return response()->json(['success'=>true,'message'=>'تم اعتماد السعر.','data'=>new OfficialPriceResource($item->load(['product','unit']))],201); }
    public function update(Request $request,OfficialPrice $officialPrice) { $data=$this->validateData($request); $old=$officialPrice->price; DB::transaction(function()use($officialPrice,$data,$old,$request){$officialPrice->update($data); if($old!=$data['price']) OfficialPriceHistory::create(['official_price_id'=>$officialPrice->id,'product_id'=>$officialPrice->product_id,'unit_id'=>$officialPrice->unit_id,'amount'=>$officialPrice->amount,'price'=>$officialPrice->price,'old_price'=>$old,'new_price'=>$data['price'],'changed_by'=>$request->user()->id,'changed_at'=>now()]);}); return response()->json(['success'=>true,'message'=>'تم تحديث السعر الرسمي.','data'=>new OfficialPriceResource($officialPrice)]); }
    public function history(OfficialPrice $officialPrice) { $items=$officialPrice->histories()->latest('changed_at')->paginate(30); return response()->json(['success'=>true,'data'=>$items->getCollection()->map(function($item){return ['id'=>(string)$item->id,'price'=>(float)$item->new_price,'changed_at'=>optional($item->changed_at)->toISOString()];})->values(),'pagination'=>$this->pagination($items)]); }
    public function destroy(OfficialPrice $officialPrice) { $officialPrice->delete(); return response()->json(['success'=>true,'message'=>'تم حذف السعر الرسمي.']); }
    protected function validateData(Request $request) { $data=$request->validate(['product_name'=>'required|string|max:255','unit'=>'required|string|max:120','quantity'=>'required|numeric|gt:0','price'=>'required|numeric|min:0']); $product=Product::where('name',$data['product_name'])->first(); $unit=Unit::where('name',$data['unit'])->first(); if(!$product) throw ValidationException::withMessages(['product_name'=>['المنتج المحدد غير موجود.']]); if(!$unit) throw ValidationException::withMessages(['unit'=>['الوحدة المحددة غير موجودة.']]); return ['product_id'=>$product->id,'unit_id'=>$unit->id,'amount'=>$data['quantity'],'price'=>$data['price']]; }
}
