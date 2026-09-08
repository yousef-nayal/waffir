<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Requests\ProductRequest;
use App\Http\Resources\ProductResource;
use App\Http\Resources\PriceResource;
use App\Models\Product;
use Illuminate\Http\Request;
class ProductController extends Controller
{
    public function index(Request $request) { $items=Product::with(['prices','officialPrices.unit','defaultUnit'])->when($request->search,function($q,$v){return $q->where('name','like','%'.$v.'%');})->when($request->category,function($q,$v){return $q->where('category',$v);})->orderBy('name')->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>ProductResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function show(Product $product) { return response()->json(['success'=>true,'data'=>new ProductResource($product->load(['prices','officialPrices.unit','defaultUnit']))]); }
    public function prices(Product $product, Request $request) { $items=$product->prices()->with(['product','store.location.sector','unit','brand','user','ratings'])->where('status','approved')->latest()->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>PriceResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function store(ProductRequest $request) { $data=$request->validated(); unset($data['unit']); if($request->filled('unit')) { $unit=\App\Models\Unit::where('name',$request->unit)->first(); if(!$unit) return response()->json(['success'=>false,'message'=>'الوحدة المحددة غير موجودة.'],422); $data['default_unit_id']=$unit->id; } $item=Product::create($data); return response()->json(['success'=>true,'message'=>'تم إنشاء المنتج.','data'=>new ProductResource($item->load('defaultUnit'))],201); }
    public function update(ProductRequest $request,Product $product) { $product->update($request->validated()); return response()->json(['success'=>true,'message'=>'تم تحديث المنتج.','data'=>new ProductResource($product)]); }
    public function destroy(Product $product) { $product->delete(); return response()->json(['success'=>true,'message'=>'تم حذف المنتج.']); }
}
