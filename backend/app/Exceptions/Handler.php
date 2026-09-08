<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    public function render($request, Throwable $exception)
    {
        if ($request->expectsJson() && $exception instanceof AuthenticationException) {
            return response()->json(['success' => false, 'message' => 'يجب تسجيل الدخول للوصول إلى هذا المورد.'], 401);
        }
        if ($request->expectsJson() && $exception instanceof AuthorizationException) {
            return response()->json(['success' => false, 'message' => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.'], 403);
        }
        if ($request->expectsJson() && $exception instanceof ValidationException) {
            return response()->json(['success' => false, 'message' => 'البيانات المدخلة غير صحيحة.',
                'errors' => $exception->errors()], 422);
        }
        if ($request->expectsJson() && $exception instanceof NotFoundHttpException) {
            return response()->json(['success' => false, 'message' => 'المورد المطلوب غير موجود.'], 404);
        }
        if ($request->expectsJson() && $exception instanceof MethodNotAllowedHttpException) {
            return response()->json(['success' => false, 'message' => 'طريقة الطلب غير مسموحة.'], 405);
        }
        return parent::render($request, $exception);
    }
    /**
     * A list of the exception types that are not reported.
     *
     * @var array<int, class-string<Throwable>>
     */
    protected $dontReport = [
        //
    ];

    /**
     * A list of the inputs that are never flashed for validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     *
     * @return void
     */
    public function register()
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }
}
