<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRequest;
use App\Http\Resources\StoreResource;
use App\Models\Store;
use App\Models\Location;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
class StoreController extends Controller
{
    public function index(Request $request) { $items=Store::where('is_active',true)->with('location.sector')->withCount('prices')->when($request->sector,function($q,$v){return $q->whereHas('location.sector',function($s)use($v){$s->where('name',$v);});})->when($request->search,function($q,$v){return $q->where('name','like','%'.$v.'%');})->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>StoreResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function show($id) { return response()->json(['success'=>true,'data'=>new StoreResource(Store::with('location.sector')->withCount('prices')->where('is_active',true)->findOrFail($id))]); }
    public function store(StoreRequest $request) { $data=$request->validated(); $location=Location::where('district',$data['area'])->whereHas('sector',function($q)use($data){$q->where('name',$data['sector']);})->first(); if(!$location) return response()->json(['success'=>false,'message'=>'الموقع المحدد غير موجود.'],422); $item=Store::create(['location_id'=>$location->id,'name'=>$data['name'],'slug'=>Str::slug($data['name'].'-'.uniqid()),'address'=>$data['address'],'is_verified'=>false]); return response()->json(['success'=>true,'message'=>'تم إرسال اقتراح المتجر.','data'=>new StoreResource($item->load('location.sector'))],201); }
    public function update(StoreRequest $request,Store $store) { $data=$request->validated(); if(isset($data['area'],$data['sector'])) { $location=Location::where('district',$data['area'])->whereHas('sector',function($q)use($data){$q->where('name',$data['sector']);})->firstOrFail(); $data['location_id']=$location->id; } unset($data['area'],$data['sector'],$data['is_verified'],$data['is_active'],$data['slug']); $store->update($data); return response()->json(['success'=>true,'message'=>'تم تحديث المتجر.','data'=>new StoreResource($store->load('location.sector'))]); }
    public function verify(Request $request, Store $store) { $data=$request->validate(['is_verified'=>'required|boolean']); $store->update(['is_verified'=>$data['is_verified']]); return response()->json(['success'=>true,'data'=>new StoreResource($store->load('location.sector'))]); }
    public function destroy(Store $store) { $store->delete(); return response()->json(['success'=>true,'message'=>'تم حذف المتجر.']); }
}
