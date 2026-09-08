<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCatalogTables extends Migration
{

public $withinTransaction = false;

    public function up()
    {
        Schema::create('brands', function (Blueprint $table) {
            $table->id(); $table->string('name'); $table->string('slug')->unique();
            $table->string('logo_url')->nullable(); $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
        Schema::create('units', function (Blueprint $table) {
            $table->id(); $table->string('name'); $table->string('symbol')->nullable();
            $table->timestamps(); $table->unique('name');
        });
        Schema::create('sectors', function (Blueprint $table) {
            $table->id(); $table->string('name'); $table->string('slug')->unique();
            $table->boolean('is_active')->default(true); $table->timestamps();
        });
        Schema::create('products', function (Blueprint $table) {
            $table->id(); $table->string('name'); $table->string('category');
            $table->timestamps(); $table->index('category');
        });
        Schema::create('locations', function (Blueprint $table) {
            $table->id();             $table->foreignId('sector_id')->constrained()->restrictOnDelete();
            $table->string('district'); $table->string('name')->nullable(); $table->string('address')->nullable(); $table->string('city')->nullable()->index();
            $table->decimal('latitude', 10, 7)->nullable(); $table->decimal('longitude', 10, 7)->nullable();
            $table->boolean('is_active')->default(true); $table->timestamps();
        });
        Schema::create('stores', function (Blueprint $table) {
            $table->id();             $table->foreignId('location_id')->constrained()->restrictOnDelete();
            $table->string('name'); $table->string('slug')->unique(); $table->string('address');
            $table->string('phone', 30)->nullable(); $table->string('logo_url')->nullable();
            $table->boolean('is_verified')->default(false); $table->boolean('is_active')->default(true)->index(); $table->timestamps(); $table->softDeletes();
        });
    }

    public function down()
    {
        Schema::dropIfExists('stores'); Schema::dropIfExists('locations'); Schema::dropIfExists('products');
        Schema::dropIfExists('sectors'); Schema::dropIfExists('units'); Schema::dropIfExists('brands');
    }
}
