<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
class Product extends Model { use HasFactory; protected $fillable = ['name','category','default_unit_id']; public function prices(){return $this->hasMany(Price::class);} public function officialPrices(){return $this->hasMany(OfficialPrice::class);} public function defaultUnit(){return $this->belongsTo(Unit::class,'default_unit_id');} }
