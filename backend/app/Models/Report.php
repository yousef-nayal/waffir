<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Report extends Model { protected $fillable = ['user_id','price_id','type','description','status']; protected $casts = ['created_at'=>'datetime','updated_at'=>'datetime']; public function user(){return $this->belongsTo(User::class);} public function price(){return $this->belongsTo(Price::class);} }
