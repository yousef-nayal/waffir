<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Requests\PriceRequest;
use App\Http\Resources\PriceResource;
use App\Models\Price;
use App\Models\Unit;
use App\Models\Brand;
use Illuminate\Validation\ValidationException;
use Illuminate\Http\Request;
class PriceController extends Controller
{
    public function index(Request $request) { $items=Price::with(['product','store.location.sector','unit','brand','user','ratings'])->when($request->product_id,function($q,$v){return $q->where('product_id',$v);})->when($request->store_id,function($q,$v){return $q->where('store_id',$v);})->when($request->status,function($q,$v){return $q->where('status',$v);})->latest()->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>PriceResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function store(PriceRequest $request) { $data=$request->validated(); $unit=Unit::where('name',$data['unit'])->first(); $brand=isset($data['brand']) ? Brand::where('name',$data['brand'])->first() : null; if(!$unit) throw ValidationException::withMessages(['unit'=>['الوحدة المحددة غير موجودة.']]); if(isset($data['brand'])&&!$brand) throw ValidationException::withMessages(['brand'=>['العلامة التجارية المحددة غير موجودة.']]); $item=Price::create(['user_id'=>$request->user()->id,'store_id'=>$data['store_id'],'product_id'=>$data['product_id'],'unit_id'=>$unit->id,'brand_id'=>optional($brand)->id,'amount'=>$data['quantity'],'price'=>$data['price'],'status'=>'pending']); return response()->json(['success'=>true,'message'=>'تمت إضافة السعر.','data'=>new PriceResource($item->load(['product','store.location.sector','unit','brand','user','ratings']))],201); }
    public function show(Price $price) { return response()->json(['success'=>true,'data'=>new PriceResource($price->load(['product','store.location.sector','unit','brand','user','ratings']))]); }
    public function vote(Request $request, Price $price) { $data=$request->validate(['is_up'=>'required|boolean']); $rating=$price->ratings()->updateOrCreate(['user_id'=>$request->user()->id],['value'=>$data['is_up']]); return response()->json(['success'=>true,'data'=>['thumbs_up'=>$price->ratings()->where('value',true)->count(),'thumbs_down'=>$price->ratings()->where('value',false)->count(),'total_ratings'=>$price->ratings()->count()]]); }
    public function review(Request $request, Price $price, $status) { abort_unless(in_array($status,['approved','rejected'],true),404); $price->update(['status'=>$status,'reviewed_by'=>$request->user()->id,'reviewed_at'=>now()]); return response()->json(['success'=>true,'data'=>new PriceResource($price->load(['product','store.location.sector','unit','brand','user','ratings']))]); }
    public function approve(Request $request, Price $price) { return $this->review($request, $price, 'approved'); }
    public function reject(Request $request, Price $price) { return $this->review($request, $price, 'rejected'); }
    public function update(PriceRequest $request, Price $price) { abort_unless($price->user_id===$request->user()->id||$request->user()->isAdmin(),403); $data=$request->validated(); $unit=Unit::where('name',$data['unit'])->first(); $brand=isset($data['brand']) ? Brand::where('name',$data['brand'])->first() : null; if(!$unit) throw ValidationException::withMessages(['unit'=>['الوحدة المحددة غير موجودة.']]); if(isset($data['brand'])&&!$brand) throw ValidationException::withMessages(['brand'=>['العلامة التجارية المحددة غير موجودة.']]); $price->update(['unit_id'=>$unit->id,'brand_id'=>optional($brand)->id,'amount'=>$data['quantity'],'price'=>$data['price']]); return response()->json(['success'=>true,'message'=>'تم تحديث السعر.','data'=>new PriceResource($price->load(['product','store.location.sector','unit','brand','user','ratings']))]); }
    public function destroy(Request $request, Price $price) { abort_unless($price->user_id===$request->user()->id||$request->user()->isAdmin(),403); $price->delete(); return response()->json(['success'=>true,'message'=>'تم حذف السعر.']); }
}
