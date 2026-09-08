<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
class Unit extends Model { use HasFactory; protected $fillable = ['name','symbol']; public function prices(){return $this->hasMany(Price::class);} public function officialPrices(){return $this->hasMany(OfficialPrice::class);} }
