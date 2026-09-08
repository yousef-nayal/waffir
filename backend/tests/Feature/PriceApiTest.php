<?php
namespace Tests\Feature;
use App\Models\Product;
use App\Models\Brand;
use App\Models\Unit;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
class PriceApiTest extends TestCase
{
    use RefreshDatabase;
    public function test_otp_login_returns_bearer_tokens()
    {
        $request=$this->postJson('/api/v1/auth/request-otp',['phone'=>'0500000000']);
        $request->assertOk()->assertJsonStructure(['success','data'=>['expires_in','debug_otp']]);
        $verify=$this->postJson('/api/v1/auth/verify-otp',['phone'=>'0500000000','code'=>$request->json('data.debug_otp')]);
        $verify->assertOk()->assertJsonPath('data.user.role','user')->assertJsonStructure(['data'=>['access_token','refresh_token','token_type']]);
    }
    public function test_user_can_submit_price_and_admin_can_view_dashboard()
    {
        $user=User::factory()->create(['role'=>0,'phone_number'=>'0500000001']); $product=Product::factory()->create(); $store=Store::factory()->create(); $unit=Unit::factory()->create(); $brand=Brand::factory()->create();
        $this->getJson('/api/v1/products/'.$product->id)->assertOk()->assertJsonPath('data.id',$product->id);
        $login=$this->postJson('/api/v1/auth/login',['phone'=>$user->phone_number,'password'=>'password']);
        $token=$login->json('data.access_token');
        $this->withHeader('Authorization','Bearer '.$token)->postJson('/api/v1/prices',['product_id'=>$product->id,'store_id'=>$store->id,'unit'=>$unit->name,'brand'=>$brand->name,'quantity'=>1,'price'=>12.5])->assertCreated();
        $admin=User::factory()->create(['role'=>2]);
        $adminLogin=$this->postJson('/api/v1/auth/admin/login',['username'=>$admin->email,'password'=>'password']);
        $adminLogin->assertOk()->assertJsonPath('data.user.role','admin');
    }

    public function test_admin_can_block_and_change_user_role()
    {
        $admin=User::factory()->create(['role'=>2]); $user=User::factory()->create(['role'=>0]);
        $login=$this->postJson('/api/v1/auth/admin/login',['username'=>$admin->email,'password'=>'password']);
        $this->withHeader('Authorization','Bearer '.$login->json('data.access_token'))->patchJson('/api/v1/admin/users/'.$user->id.'/block')->assertOk();
        $this->assertDatabaseHas('users',['id'=>$user->id,'is_active'=>0]);
        $this->withHeader('Authorization','Bearer '.$login->json('data.access_token'))->patchJson('/api/v1/admin/users/'.$user->id.'/role',['role'=>1])->assertOk();
        $this->assertDatabaseHas('users',['id'=>$user->id,'role'=>1]);
    }
}
