<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable;

    const ROLE_USER = 0;
    const ROLE_EDITOR = 1;
    const ROLE_ADMIN = 2;

    protected static function booted()
    {
        static::creating(function ($user) {
            if ($user->is_active === null) $user->is_active = true;
            if ($user->role === null) $user->role = 0;
        });
    }

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = ['name', 'email', 'phone_number', 'password', 'role', 'location_id', 'is_active'];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_active' => 'boolean',
        'role' => 'integer',
    ];

    public function prices()
    {
        return $this->hasMany(Price::class);
    }

    public function ratings()
    {
        return $this->hasMany(Rating::class);
    }

    public function reports()
    {
        return $this->hasMany(Report::class);
    }
    public function location() { return $this->belongsTo(Location::class); }

    public function isAdmin()
    {
        return (int) $this->role === 2;
    }

    public function isEditor()
    {
        return in_array((int) $this->role, [1, 2], true);
    }

    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [];
    }
}
