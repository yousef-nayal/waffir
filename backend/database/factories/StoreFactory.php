<?php
namespace Database\Factories;
use App\Models\Store;
use App\Models\Location;
use App\Models\Sector;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;
class StoreFactory extends Factory { protected $model=Store::class; public function definition(){ $n=$this->faker->unique()->company(); return ['location_id'=>function(){ $sector=Sector::factory()->create(); return Location::factory()->create(['sector_id'=>$sector->id])->id; },'name'=>$n,'slug'=>Str::slug($n),'address'=>$this->faker->address(),'is_verified'=>false,'is_active'=>true];} }
