<?php
namespace Database\Factories;
use App\Models\Price;
use App\Models\Product;
use App\Models\Store;
use App\Models\Unit;
use App\Models\Brand;
use Illuminate\Database\Eloquent\Factories\Factory;
class PriceFactory extends Factory { protected $model=Price::class; public function definition(){return ['user_id'=>\App\Models\User::factory(),'store_id'=>Store::factory(),'product_id'=>Product::factory(),'unit_id'=>Unit::factory(),'brand_id'=>Brand::factory(),'amount'=>1,'price'=>$this->faker->randomFloat(2,1,500)];} }
