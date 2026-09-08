<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Requests\CatalogRequest;
use App\Http\Resources\BasicResource;
use App\Models\Brand;
use App\Models\Sector;
use App\Models\Unit;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
class CatalogController extends Controller
{
    protected function model($type) { $map=['brands'=>Brand::class,'units'=>Unit::class,'sectors'=>Sector::class]; abort_unless(isset($map[$type]),404); return $map[$type]; }
    public function index(Request $request,$type) { $model=$this->model($type); $items=$model::query()->when($type !== 'units',function($q){return $q->where('is_active',true);})->when($request->search,function($q,$v){return $q->where('name','like','%'.$v.'%');})->orderBy('name')->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>BasicResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function show($type,$id) { $model=$this->model($type); return response()->json(['success'=>true,'data'=>new BasicResource($model::findOrFail($id))]); }
    public function store(CatalogRequest $request,$type) { $model=$this->model($type); $data=$request->validated(); if ($type !== 'units') $data['slug']=$data['slug']??Str::slug($data['name']); $item=$model::create($data); return response()->json(['success'=>true,'message'=>'تم الإنشاء بنجاح.','data'=>new BasicResource($item)],201); }
    public function update(CatalogRequest $request,$type,$id) { $model=$this->model($type); $item=$model::findOrFail($id); $item->update($request->validated()); return response()->json(['success'=>true,'message'=>'تم التحديث بنجاح.','data'=>new BasicResource($item)]); }
    public function destroy($type,$id) { $model=$this->model($type); $model::findOrFail($id)->delete(); return response()->json(['success'=>true,'message'=>'تم الحذف بنجاح.']); }
}
