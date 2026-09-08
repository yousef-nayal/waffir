<?php
namespace App\Http\Controllers\Api\V1;
use App\Http\Controllers\Controller;
use App\Http\Requests\OtpRequest;
use App\Http\Requests\VerifyOtpRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Models\User;
class AuthController extends Controller
{
    protected $auth;
    public function __construct(AuthService $auth) { $this->auth = $auth; }
    public function requestOtp(OtpRequest $request) {
        $code = $this->auth->requestOtp($request->phone, $request->input('purpose', 'login'));
        $data = ['expires_in'=>300];
        if (app()->environment(['local','testing'])) $data['debug_otp'] = $code;
        return response()->json(['success'=>true,'message'=>'تم إرسال رمز التحقق.','data'=>$data]);
    }
    public function verifyOtp(VerifyOtpRequest $request) {
        list($user,$tokens) = $this->auth->verifyOtp($request->phone,$request->code,$request->name,$request->input('purpose','login'));
        return response()->json(['success'=>true,'message'=>'تم تسجيل الدخول بنجاح.','data'=>array_merge($tokens,['user'=>new UserResource($user)])]);
    }
    public function me(Request $request) { return response()->json(['success'=>true,'data'=>new UserResource($request->user())]); }
    public function refresh(Request $request){$data = $request->validate(['refresh_token' => 'required|string']);return response()->json(array_merge(['success' => true],$this->auth->refresh($data['refresh_token'])));}
    public function logout(Request $request) { if ($request->bearerToken()) $this->auth->revokeToken($request->bearerToken()); return response()->json(['success'=>true,'message'=>'تم تسجيل الخروج.']); }
    public function login(Request $request) { $data=$request->validate(['phone'=>'required|string|max:30','password'=>'required|string']); list($user,$tokens)=$this->auth->passwordLogin($data['phone'],$data['password']); return response()->json(['success'=>true,'data'=>array_merge($tokens,['user'=>new UserResource($user)])]); }
    public function register(Request $request){$data = $request->validate(['name' => 'required|string|max:120','phone' => 'required|string|max:30|unique:users,phone_number','password' => 'required|string|min:8|confirmed','sector' => 'nullable|string|max:255',]);$locationId = null;if (!empty($data['sector'])) {$parts = array_map('trim', explode(' - ', $data['sector'], 2));$sectorName = $parts[0] ?? null;$locationName = $parts[1] ?? null;if (!$sectorName || !$locationName) {return response()->json(['success' => false,'message' => 'الموقع غير صالح.',], 422);}$sector = \App\Models\Sector::where('name', $sectorName)->first();if (!$sector) {return response()->json(['success' => false,'message' => 'القطاع غير موجود.',], 422);}$location = \App\Models\Location::where('sector_id', $sector->id)->where('district', $locationName)->first();if (!$location) {return response()->json(['success' => false,'message' => 'المنطقة غير موجودة ضمن القطاع المحدد.',], 422);}$locationId = $location->id;}$data['phone_number'] = $data['phone'];$data['location_id'] = $locationId;unset($data['phone'], $data['sector']);$data['password'] = Hash::make($data['password']);$user = User::create($data);return response()->json(['success' => true,'message' => 'تم إنشاء الحساب.','data' => array_merge($this->auth->issueTokens($user),['user' => new UserResource($user)]),], 201);}
    public function forgotPassword(OtpRequest $request) { $code=$this->auth->requestOtp($request->phone,'forgot_password'); $data=['expires_in'=>300]; if(app()->environment(['local','testing']))$data['debug_otp']=$code; return response()->json(['success'=>true,'message'=>'تم إرسال رمز استعادة كلمة المرور.','data'=>$data]); }
    public function resendOtp(OtpRequest $request) { return $this->requestOtp($request); }
    public function adminLogin(Request $request) { $data=$request->validate(['username'=>'required|string','password'=>'required|string']); list($user,$tokens)=$this->auth->passwordLogin($data['username'],$data['password']); if((int)$user->role===0)return response()->json(['success'=>false,'message'=>'لا تملك صلاحية الإدارة.'],403); return response()->json(['success'=>true,'data'=>array_merge($tokens,['user'=>new UserResource($user)])]); }
    public function resetPassword(Request $request) { $data=$request->validate(['phone'=>'required|string','code'=>'required|digits:6','new_password'=>'required|string|min:8|confirmed']); $this->auth->verifyOtp($data['phone'],$data['code'],null,'forgot_password'); $user=User::where('phone_number',$data['phone'])->firstOrFail(); $user->update(['password'=>Hash::make($data['new_password'])]); return response()->json(['success'=>true,'message'=>'تم إعادة تعيين كلمة المرور.']); }
    public function changePassword(Request $request) { $data=$request->validate(['current_password'=>'required|string','new_password'=>'required|string|min:8|confirmed']); if(!Hash::check($data['current_password'],$request->user()->password)) throw ValidationException::withMessages(['current_password'=>['كلمة المرور الحالية غير صحيحة.']]); $request->user()->update(['password'=>Hash::make($data['new_password'])]); return response()->json(['success'=>true,'message'=>'تم تغيير كلمة المرور.']); }
    public function profile(Request $request) { $data=$request->validate(['name'=>'sometimes|string|max:120']); $request->user()->update($data); return response()->json(['success'=>true,'message'=>'تم تحديث الملف الشخصي.','data'=>new UserResource($request->user())]); }
}
