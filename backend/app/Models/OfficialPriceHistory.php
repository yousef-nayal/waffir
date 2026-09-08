<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class OfficialPriceHistory extends Model { protected $fillable = ['official_price_id','product_id','unit_id','amount','price','old_price','new_price','changed_by','changed_at']; protected $casts = ['amount'=>'float','price'=>'float','old_price'=>'float','new_price'=>'float','changed_at'=>'datetime']; public function officialPrice(){return $this->belongsTo(OfficialPrice::class);} public function user(){return $this->belongsTo(User::class,'changed_by');} }
