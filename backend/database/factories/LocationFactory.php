<?php
namespace Database\Factories;
use App\Models\Location;
use Illuminate\Database\Eloquent\Factories\Factory;
class LocationFactory extends Factory { protected $model=Location::class; public function definition(){return ['district'=>$this->faker->city(),'name'=>$this->faker->city(),'city'=>$this->faker->city(),'is_active'=>true];} }
