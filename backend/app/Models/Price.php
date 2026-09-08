<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
class Price extends Model { use HasFactory; protected $fillable = ['user_id','store_id','product_id','unit_id','brand_id','amount','price','status','reviewed_by','reviewed_at']; protected $casts = ['amount'=>'float','price'=>'float','reviewed_at'=>'datetime']; public function product(){return $this->belongsTo(Product::class);} public function store(){return $this->belongsTo(Store::class);} public function user(){return $this->belongsTo(User::class);} public function reviewer(){return $this->belongsTo(User::class,'reviewed_by');} public function unit(){return $this->belongsTo(Unit::class);} public function brand(){return $this->belongsTo(Brand::class);} public function ratings(){return $this->hasMany(Rating::class);} public function reports(){return $this->hasMany(Report::class);} }
