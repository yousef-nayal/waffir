<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
class Location extends Model { use HasFactory; protected $fillable = ['sector_id','district','name','address','city','latitude','longitude','is_active']; protected $casts = ['latitude'=>'float','longitude'=>'float','is_active'=>'boolean']; public function sector(){return $this->belongsTo(Sector::class);} public function stores(){return $this->hasMany(Store::class);} }
