<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Requests\RatingRequest;
use App\Http\Resources\RatingResource;
use App\Models\Rating;
use Illuminate\Http\Request;
class RatingController extends Controller
{
    public function index(Request $request) { $items=Rating::where('price_id',$request->route('price'))->with('user')->latest()->paginate(20); return response()->json(['success'=>true,'data'=>RatingResource::collection($items)]); }
    public function store(RatingRequest $request) { $data=$request->validated(); $data['user_id']=$request->user()->id; $item=Rating::updateOrCreate(['price_id'=>$data['price_id'],'user_id'=>$data['user_id']],$data); return response()->json(['success'=>true,'message'=>'تم حفظ التقييم.','data'=>new RatingResource($item)],201); }
    public function destroy(Request $request,Rating $rating) { abort_unless($rating->user_id===$request->user()->id||$request->user()->isAdmin(),403); $rating->delete(); return response()->json(['success'=>true,'message'=>'تم حذف التقييم.']); }
    public function update(RatingRequest $request,Rating $rating) { abort_unless($rating->user_id===$request->user()->id||$request->user()->isAdmin(),403); $rating->update($request->validated()); return response()->json(['success'=>true,'message'=>'تم تحديث التقييم.','data'=>new RatingResource($rating)]); }
}
