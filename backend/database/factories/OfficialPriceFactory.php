<?php
namespace Database\Factories;
use App\Models\OfficialPrice;
use App\Models\Product;
use App\Models\Unit;
use Illuminate\Database\Eloquent\Factories\Factory;
class OfficialPriceFactory extends Factory { protected $model=OfficialPrice::class; public function definition(){return ['product_id'=>Product::factory(),'unit_id'=>Unit::factory(),'amount'=>1,'price'=>$this->faker->randomFloat(2,1,500)];} }
