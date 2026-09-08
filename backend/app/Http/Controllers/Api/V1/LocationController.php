<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Resources\LocationResource;
use App\Models\Sector;
use App\Models\Location;
use Illuminate\Http\Request;
class LocationController extends Controller
{
    public function index(Request $request) { $items=Location::where('is_active',true)->with('sector')->withCount('stores')->when($request->search,function($q,$v){return $q->where('district','like','%'.$v.'%')->orWhereHas('sector',function($s)use($v){$s->where('name','like','%'.$v.'%');});})->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>LocationResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function show($id) { return response()->json(['success'=>true,'data'=>new LocationResource(Location::with('sector')->withCount('stores')->where('is_active',true)->findOrFail($id))]); }
    public function store(Request $request) { $data=$request->validate(['sector'=>'required|string|max:255','area'=>'required|string|max:255','landmark'=>'nullable|string|max:500']); $sector=Sector::where('name',$data['sector'])->first(); if(!$sector)return response()->json(['success'=>false,'message'=>'القطاع المحدد غير موجود.'],422); $item=Location::create(['sector_id'=>$sector->id,'district'=>$data['area'],'address'=>$data['landmark']??null]); return response()->json(['success'=>true,'message'=>'تم إنشاء الموقع.','data'=>new LocationResource($item->load('sector'))],201); }
    public function update(Request $request,Location $location) { $location->update($request->validate(['name'=>'sometimes|string|max:255','address'=>'nullable|string|max:500','city'=>'nullable|string|max:100','is_active'=>'sometimes|boolean'])); return response()->json(['success'=>true,'message'=>'تم تحديث الموقع.','data'=>new BasicResource($location)]); }
    public function destroy(Location $location) { $location->delete(); return response()->json(['success'=>true,'message'=>'تم حذف الموقع.']); }
}
