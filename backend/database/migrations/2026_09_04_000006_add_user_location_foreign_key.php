<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
class AddUserLocationForeignKey extends Migration
{
public $withinTransaction = false;

    public function up() { Schema::table('users', function (Blueprint $table) { $table->foreign('location_id')->references('id')->on('locations')->nullOnDelete(); }); }
    public function down() { Schema::table('users', function (Blueprint $table) { $table->dropForeign(['location_id']); }); }
}
