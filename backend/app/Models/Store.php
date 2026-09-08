<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;
class Store extends Model { use HasFactory, SoftDeletes; protected $fillable = ['location_id','name','slug','address','phone','logo_url','is_verified','is_active']; protected $casts = ['is_verified'=>'boolean','is_active'=>'boolean']; public function location(){return $this->belongsTo(Location::class);} public function prices(){return $this->hasMany(Price::class);} public function officialPrices(){return $this->hasMany(OfficialPrice::class);} public function ratings(){return $this->hasMany(Rating::class);} }
