<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class RepairFlutterContract extends Migration
{
public $withinTransaction = false;

    public function up()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->foreignId('default_unit_id')->nullable()->after('category')->constrained('units')->nullOnDelete();
        });
        Schema::table('prices', function (Blueprint $table) {
            $table->string('status')->default('pending')->after('price')->index();
            $table->foreignId('reviewed_by')->nullable()->after('status')->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable()->after('reviewed_by');
            $table->index(['product_id', 'store_id', 'created_at']);
            $table->index(['user_id', 'status']);
        });
        Schema::table('reports', function (Blueprint $table) {
            $table->string('status')->default('pending')->after('description')->index();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::table('reports', function (Blueprint $table) {
            $table->dropColumn('status');
            $table->dropTimestamps();
        });
        Schema::table('prices', function (Blueprint $table) {
            $table->dropForeign(['reviewed_by']);
            $table->dropIndex(['product_id', 'store_id', 'created_at']);
            $table->dropIndex(['user_id', 'status']);
            $table->dropColumn(['status', 'reviewed_by', 'reviewed_at']);
        });
        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign(['default_unit_id']);
            $table->dropColumn('default_unit_id');
        });
    }
}