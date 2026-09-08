<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Http\Resources\ReportResource;
use App\Models\Brand;
use App\Models\Product;
use App\Models\Report;
use App\Models\Store;
use App\Models\User;
use Illuminate\Http\Request;
class AdminController extends Controller
{
    public function users(Request $request){$users = User::when($request->search, function ($q, $v) {return $q->where(function ($query) use ($v) {$query->where('name', 'like', '%' . $v . '%')->orWhere('phone_number', $v)->orWhere('email', $v);});})->when($request->status, function ($q, $status) {return $q->where('is_active', $status === 'active');})->latest()->paginate($request->per_page ?? 20);return response()->json(['success' => true,'data' => UserResource::collection($users),]);}
    public function updateUser(Request $request,User $user) { $data=$request->validate(['role'=>'sometimes|integer|between:0,2','is_active'=>'sometimes|boolean'],['role.between'=>'دور المستخدم غير صالح.']); $user->update($data); return response()->json(['success'=>true,'message'=>'تم تحديث المستخدم.','data'=>new UserResource($user)]); }
    public function block(User $user) { $user->update(['is_active'=>false]); return response()->json(['success'=>true,'message'=>'تم حظر المستخدم.']); }
    public function unblock(User $user) { $user->update(['is_active'=>true]); return response()->json(['success'=>true,'message'=>'تم إلغاء حظر المستخدم.']); }
    public function role(Request $request, User $user){$data = $request->validate(['role' => 'required|string|in:user,editor,admin',]);$roleMap = ['user' => User::ROLE_USER,'editor' => User::ROLE_EDITOR,'admin' => User::ROLE_ADMIN,];$user->update(['role' => $roleMap[$data['role']],]);return response()->json(['success' => true,'message' => 'تم تحديث دور المستخدم.','data' => new UserResource($user),]);}
    public function dashboard() { $users=User::count(); $products=Product::count(); $stores=Store::count(); $prices=\App\Models\Price::count(); $reports=Report::count(); return response()->json(['success'=>true,'data'=>['totalUsers'=>$users,'totalProducts'=>$products,'totalStores'=>$stores,'totalPrices'=>$prices,'totalReports'=>$reports,'usersGrowth'=>0,'productsGrowth'=>0,'storesGrowth'=>0,'pricesGrowth'=>0,'users'=>$users,'products'=>$products,'stores'=>$stores,'prices'=>$prices,'reports'=>$reports]]); }
    public function recentActivity(){$prices = \App\Http\Resources\PriceResource::collection(\App\Models\Price::latest()->limit(10)->get());$reports = ReportResource::collection(Report::latest()->limit(10)->get());return response()->json(['success' => true,'data' => array_merge($prices->resolve(),$reports->resolve()),]);}
}
