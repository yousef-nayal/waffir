<?php
namespace Database\Factories;
use App\Models\Sector;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;
class SectorFactory extends Factory { protected $model=Sector::class; public function definition(){ $n=$this->faker->unique()->word(); return ['name'=>$n,'slug'=>Str::slug($n),'is_active'=>true]; } }
