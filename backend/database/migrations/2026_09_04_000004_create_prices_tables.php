<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePricesTables extends Migration
{

public $withinTransaction = false;

    public function up()
    {
        Schema::create('official_prices', function (Blueprint $table) {
            $table->id(); $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('unit_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 12, 3); $table->decimal('price', 12, 3);
            $table->timestamps(); $table->index(array('product_id', 'unit_id'));
        });
        Schema::create('official_price_histories', function (Blueprint $table) {
            $table->id(); $table->foreignId('official_price_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('unit_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 12, 3); $table->decimal('price', 12, 3);
            $table->decimal('old_price', 12, 3)->nullable(); $table->decimal('new_price', 12, 3)->nullable();
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('changed_at'); $table->timestamps();
        });
        Schema::create('prices', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('store_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('unit_id')->constrained()->cascadeOnDelete();
            $table->foreignId('brand_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 12, 3); $table->decimal('price', 12, 3);
            $table->timestamps(); $table->index(array('product_id', 'store_id'));
        });
        Schema::create('ratings', function (Blueprint $table) {
            $table->id(); $table->foreignId('price_id')->constrained('prices')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->boolean('value'); $table->timestamps();
            $table->unique(array('price_id', 'user_id'));
        });
    }

    public function down()
    {
        Schema::dropIfExists('ratings'); Schema::dropIfExists('prices');
        Schema::dropIfExists('official_price_histories'); Schema::dropIfExists('official_prices');
    }
}
