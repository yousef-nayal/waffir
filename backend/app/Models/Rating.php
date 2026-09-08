<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Rating extends Model { protected $fillable = ['price_id','user_id','value']; protected $casts = ['value'=>'boolean']; public function price(){return $this->belongsTo(Price::class);} public function user(){return $this->belongsTo(User::class);} }
