<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
class Sector extends Model { use HasFactory; protected $fillable = ['name','slug','is_active']; protected $casts = ['is_active'=>'boolean']; public function locations(){return $this->hasMany(Location::class);} }
