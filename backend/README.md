# Waffir Price API

واجهة Waffir لتتبع أسعار المنتجات ومقارنتها بين المتاجر. تعمل على Laravel 8
وPHP 7.3+ وPostgreSQL، وتستخدم رموز Sanctum المحمولة بصيغة Bearer (مناسبة
لتطبيق Flutter).

## التشغيل

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

## API v1

المسارات تحت `/api/v1`. الاستجابات تستخدم `success`, `data`, `message`، وقوائم
النتائج تعيد pagination Laravel (`current_page`, `last_page`, `per_page`, `total`).

- `POST /auth/login`, `/auth/register`, `/auth/admin/login`.
- `POST /auth/forgot-password`, `/auth/verify-otp`, `/auth/resend-otp`,
  `/auth/reset-password`.
- `GET /auth/me`, `POST /auth/refresh`, `POST /auth/logout`,
  `POST /auth/change-password`, `PUT /auth/profile`.
- `GET /brands`, `/units`, `/sectors`, `/products`, `/locations`, `/stores`.
- `GET /prices`, `/official-prices` و`GET /prices/{id}/ratings`.
- المستخدم المسجل يضيف `POST /prices`, `POST /ratings`, `POST /reports`.
- الدور 1 لإدارة بيانات الكتالوج، والدور 2 للإدارة والأسعار الرسمية.
- الإدارة: `/admin/users`, `/admin/users/{id}/block|unblock|role`,
  `/admin/dashboard-stats`, `/admin/recent-activity`, `/admin/reports`.

أرسل `Authorization: Bearer <access_token>`. رمز OTP لا يظهر إلا في بيئتي
`local` و`testing` لتسهيل التطوير؛ في الإنتاج يرسل عبر مزود SMS/بريد.

الأدوار: `0` مستخدم، `1` مدخل بيانات، `2` مدير. الحسابات غير النشطة مرفوضة.
حد OTP خمس محاولات وصلاحيته خمس دقائق، وتستخدم الأسعار الرسمية سجلاً
تاريخياً لكل تغيير.

## الاختبارات

```bash
php artisan test
```

## النشر على Render

ملف `render.yaml` في جذر المستودع ينشئ خدمة الويب وقاعدة PostgreSQL تلقائياً.
بعد دفع المستودع إلى GitHub:

1. في Render اختر **New > Blueprint** واربط مستودع GitHub.
2. اختر المستودع الذي يحتوي على `render.yaml` واضغط **Apply**.
3. انتظر بناء Docker وتشغيل الترحيلات تلقائياً.

الخدمة تستخدم `backend/Dockerfile`. يتم حقن `APP_KEY` و`JWT_SECRET` تلقائياً،
وتأتي `DATABASE_URL` من قاعدة PostgreSQL التي ينشئها Render. لا تضع أي أسرار في
GitHub. إذا غُيّر اسم الخدمة، حدّث `APP_URL` في `render.yaml` إلى رابط Render
الجديد.

للاختبارات استخدم SQLite في الذاكرة كما هو مضبوط في `phpunit.xml`.
