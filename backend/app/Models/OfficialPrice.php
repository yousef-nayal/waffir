<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
class OfficialPrice extends Model { use HasFactory; protected $fillable = ['product_id','unit_id','amount','price']; protected $casts = ['amount'=>'float','price'=>'float']; public function product(){return $this->belongsTo(Product::class);} public function unit(){return $this->belongsTo(Unit::class);} public function histories(){return $this->hasMany(OfficialPriceHistory::class);} }
