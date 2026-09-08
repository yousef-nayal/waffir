<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Otp extends Model { protected $fillable = ['identifier','code_hash','purpose','expires_at','attempts','consumed_at']; protected $casts = ['expires_at'=>'datetime','consumed_at'=>'datetime']; }
