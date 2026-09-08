<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        $admin = \App\Models\User::factory()->create(['name' => 'مدير النظام', 'email' => 'admin@waffir.test', 'role' => 2]);
        $editor = \App\Models\User::factory()->create(['name' => 'مدخل بيانات', 'email' => 'editor@waffir.test', 'role' => 1]);
        $brand = \App\Models\Brand::factory()->create(['name' => 'وفّر']);
        $unit = \App\Models\Unit::factory()->create(['name' => 'قطعة']);
        $sector = \App\Models\Sector::factory()->create(['name' => 'البقالة']);
        $location = \App\Models\Location::factory()->create(['sector_id' => $sector->id]);
        $store = \App\Models\Store::factory()->create(['location_id' => $location->id]);
        $product = \App\Models\Product::factory()->create();
        \App\Models\OfficialPrice::factory()->create(['product_id' => $product->id, 'unit_id' => $unit->id]);
        \App\Models\Price::factory()->create(['product_id' => $product->id, 'store_id' => $store->id, 'user_id' => $editor->id, 'unit_id' => $unit->id, 'brand_id' => $brand->id]);
    }
}
