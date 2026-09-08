<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateReportsAndOtpsTables extends Migration
{

public $withinTransaction = false;

    public function up()
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('price_id')->constrained('prices')->cascadeOnDelete();
            $table->string('type'); $table->text('description')->nullable();
        });
        Schema::create('otps', function (Blueprint $table) {
            $table->id(); $table->string('identifier', 190)->index(); $table->string('code_hash');
            $table->string('purpose')->default('login'); $table->timestamp('expires_at');
            $table->unsignedTinyInteger('attempts')->default(0); $table->timestamp('consumed_at')->nullable();
            $table->timestamps(); $table->index(array('identifier', 'purpose', 'expires_at'));
        });
    }

    public function down()
    {
        Schema::dropIfExists('otps'); Schema::dropIfExists('reports');
    }
}
