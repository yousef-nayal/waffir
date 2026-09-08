<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\AdminController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\LocationController;
use App\Http\Controllers\Api\V1\OfficialPriceController;
use App\Http\Controllers\Api\V1\PriceController;
use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\RatingController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\StoreController;

Route::prefix('v1')->group(function () {
    Route::get('health', function () { return response()->json(['success' => true, 'message' => 'الخدمة تعمل.']); });
    Route::prefix('auth')->group(function () {
        Route::post('request-otp', [AuthController::class, 'requestOtp'])->middleware('throttle:auth');
        Route::post('verify-otp', [AuthController::class, 'verifyOtp'])->middleware('throttle:auth');
        Route::post('resend-otp', [AuthController::class, 'resendOtp'])->middleware('throttle:auth');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:auth');
        Route::post('admin/login', [AuthController::class, 'adminLogin'])->middleware('throttle:auth');
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:auth');
        Route::post('forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:auth');
        Route::put('reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:auth');
        Route::post('refresh', [AuthController::class, 'refresh'])->middleware('throttle:auth');
        Route::middleware(['auth:api', 'access', 'active'])->group(function () {
            Route::get('me', [AuthController::class, 'me']);
            Route::post('logout', [AuthController::class, 'logout']);
            Route::put('change-password', [AuthController::class, 'changePassword']);
            Route::put('profile', [AuthController::class, 'profile']);
        });
    });

    Route::get('prices/{price}/ratings', [RatingController::class, 'index']);
    Route::get('products', [ProductController::class, 'index']);
    Route::get('products/{product}', [ProductController::class, 'show']);
    Route::get('products/{product}/prices', [ProductController::class, 'prices']);
    Route::get('locations', [LocationController::class, 'index']);
    Route::get('locations/{location}', [LocationController::class, 'show']);
    Route::get('stores', [StoreController::class, 'index']);
    Route::get('stores/{store}', [StoreController::class, 'show']);
    Route::get('official-prices', [OfficialPriceController::class, 'index']);
    Route::get('official-prices/{officialPrice}', [OfficialPriceController::class, 'show']);
    Route::get('prices', [PriceController::class, 'index']);
    Route::get('prices/{price}', [PriceController::class, 'show']);
    Route::get('{type}', [CatalogController::class, 'index'])->where('type', 'brands|units|sectors');
    Route::get('{type}/{id}', [CatalogController::class, 'show'])->where('type', 'brands|units|sectors');

    Route::middleware(['auth:api', 'access', 'active'])->group(function () {
        Route::post('prices', [PriceController::class, 'store']);
            Route::post('prices/{price}/vote', [PriceController::class, 'vote']);
        Route::post('stores', [StoreController::class, 'store']);
        Route::put('prices/{price}', [PriceController::class, 'update']);
        Route::patch('prices/{price}/approve', [PriceController::class, 'approve'])->middleware('role:2');
        Route::patch('prices/{price}/reject', [PriceController::class, 'reject'])->middleware('role:2');
        Route::delete('prices/{price}', [PriceController::class, 'destroy']);
        Route::post('ratings', [RatingController::class, 'store']);
        Route::put('ratings/{rating}', [RatingController::class, 'update']);
        Route::delete('ratings/{rating}', [RatingController::class, 'destroy']);
        Route::get('reports', [ReportController::class, 'index']);
        Route::post('reports', [ReportController::class, 'store']);
        Route::patch('reports/{report}', [ReportController::class, 'update'])->middleware('role:2');
        Route::get('reports/{report}', [ReportController::class, 'show']);
        Route::delete('reports/{report}', [ReportController::class, 'destroy']);
        Route::middleware('role:1,2')->group(function () {
            Route::post('brands', [CatalogController::class, 'store']);
            Route::post('units', [CatalogController::class, 'store']);
            Route::post('sectors', [CatalogController::class, 'store']);
            Route::post('products', [ProductController::class, 'store']);
            Route::put('products/{product}', [ProductController::class, 'update']);
            Route::delete('products/{product}', [ProductController::class, 'destroy']);
            Route::post('locations', [LocationController::class, 'store']);
            Route::put('locations/{location}', [LocationController::class, 'update']);
            Route::put('stores/{store}', [StoreController::class, 'update']);
            Route::patch('stores/{store}/verify', [StoreController::class, 'verify'])->middleware('role:2');
        });
        Route::middleware('role:2')->group(function () {
            Route::put('{type}/{id}', [CatalogController::class, 'update'])->where('type', 'brands|units|sectors');
            Route::delete('{type}/{id}', [CatalogController::class, 'destroy'])->where('type', 'brands|units|sectors');
            Route::delete('stores/{store}', [StoreController::class, 'destroy']);
            Route::delete('locations/{location}', [LocationController::class, 'destroy']);
            Route::post('official-prices', [OfficialPriceController::class, 'store']);
            Route::put('official-prices/{officialPrice}', [OfficialPriceController::class, 'update']);
            Route::delete('official-prices/{officialPrice}', [OfficialPriceController::class, 'destroy']);
            Route::get('official-prices/{officialPrice}/history', [OfficialPriceController::class, 'history']);
            Route::get('admin/users', [AdminController::class, 'users']);
            Route::put('admin/users/{user}', [AdminController::class, 'updateUser']);
            Route::patch('admin/users/{user}/block', [AdminController::class, 'block']);
            Route::patch('admin/users/{user}/unblock', [AdminController::class, 'unblock']);
            Route::patch('admin/users/{user}/role', [AdminController::class, 'role']);
            Route::get('admin/dashboard-stats', [AdminController::class, 'dashboard']);
            Route::get('admin/recent-activity', [AdminController::class, 'recentActivity']);
            Route::get('admin/reports', [ReportController::class, 'adminIndex']);
        });
    });
});
