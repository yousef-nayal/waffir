<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Requests\ReportRequest;
use App\Http\Resources\ReportResource;
use App\Models\Report;
use Illuminate\Http\Request;
class ReportController extends Controller
{
    public function index(Request $request) { $items=Report::where('user_id',$request->user()->id)->with(['price.product','price.store.location.sector','user'])->latest()->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>ReportResource::collection($items),'pagination'=>$this->pagination($items)]); }
    public function store(ReportRequest $request) { $data=$request->validated(); $item=Report::create(['user_id'=>$request->user()->id,'price_id'=>$data['price_entry_id'],'type'=>$data['type'],'description'=>$data['note']??null,'status'=>'pending']); return response()->json(['success'=>true,'message'=>'تم إرسال البلاغ.','data'=>new ReportResource($item->load(['price.product','price.store.location.sector','user']))],201); }
    public function show(Request $request, Report $report) { abort_unless($report->user_id===$request->user()->id||$request->user()->isAdmin(),403); return response()->json(['success'=>true,'data'=>new ReportResource($report)]); }
    public function destroy(Request $request, Report $report) { abort_unless($report->user_id===$request->user()->id||$request->user()->isAdmin(),403); $report->delete(); return response()->json(['success'=>true,'message'=>'تم حذف البلاغ.']); }
    public function update(Request $request, Report $report) { $data=$request->validate(['status'=>'required|in:pending,reviewed,resolved']); $report->update($data); return response()->json(['success'=>true,'data'=>new ReportResource($report->load(['price.product','price.store.location.sector','user']))]); }
    public function adminIndex(Request $request) { $items=Report::with(['user','price.product','price.store.location.sector'])->when($request->status,function($q,$v){return $q->where('status',$v);})->latest()->paginate(min(max((int)$request->input('per_page',20),1),100)); return response()->json(['success'=>true,'data'=>ReportResource::collection($items),'pagination'=>$this->pagination($items)]); }
}
