# توثيق API — تطبيق وفّر (Waffir)

هذا المستند هو المرجع الوحيد الذي يحتاجه مطوّر الـ backend لبناء الـ API الذي
يتصل به تطبيق وفّر. كل شكل JSON هنا مطابق تماماً لِـ `fromJson`/`toJson` في
`lib/models/models.dart`، وكل مسار (endpoint) مطابق لما يستدعيه كل Service في
`lib/core/network/services/` و `lib/features/auth/data/auth_service.dart`.

## 0. كيف يعمل التطبيق الآن ولماذا

التطبيق حالياً يعمل بالكامل على **بيانات وهمية (Mock Data)** لأغراض العرض
والتصميم. مفتاح التبديل موجود في ملف واحد:

```
lib/core/config/app_config.dart
  static const bool useMockData = true;   // غيّرها إلى false عند التسليم
```

كل شاشة في التطبيق مبنية بالفعل فوق طبقة الـ API (ApiClient + Services +
Providers)، لذا لا حاجة لتعديل أي واجهة عند ربط الـ backend — فقط:

1. ابنِ الـ endpoints أدناه بنفس الشكل تماماً.
2. غيّر `useMockData` إلى `false`.
3. شغّل التطبيق مع:
   ```
   flutter run --dart-define=API_BASE_URL=https://your-domain.com/v1
   ```

## 1. القواعد العامة

- **Base URL**: يُمرَّر عبر `--dart-define=API_BASE_URL=...` (افتراضياً
  `https://api.waffir.sy/v1`).
- **الترميز**: كل الطلبات والردود JSON، `Content-Type: application/json`.
- **اللغة**: يرسل التطبيق `Accept-Language: ar` — رسائل الأخطاء يجب أن تكون
  بالعربية لتظهر مباشرة للمستخدم.
- **المصادقة**: JWT عبر `Authorization: Bearer <access_token>` على كل الطلبات
  المحمية (كل شيء عدا auth/login, auth/register, auth/admin/login,
  auth/forgot-password).
- **شكل الرد الموحّد** (أي endpoint يُرجع قائمة أو عنصر واحد يتبع هذا الشكل):

```json
{
  "success": true,
  "data": { /* أو [ ] لقائمة */ },
  "message": "نص اختياري",
  "pagination": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 93
  }
}
```

`pagination` يظهر فقط في الـ endpoints التي تُرجع قوائم قابلة للترقيم.

- **أخطاء**: أي كود حالة غير 2xx يجب أن يُرجع:

```json
{ "success": false, "message": "رسالة الخطأ بالعربية", "errors": { "field": ["..."] } }
```

أكواد الحالة التي يتعرف عليها التطبيق: `401` (منتهي الجلسة)، `403` (ممنوع)،
`404` (غير موجود)، `422` (خطأ تحقق/validation، مع `errors`)، `500+` (خطأ خادم).

---

## 2. المصادقة (Auth)

### POST /auth/login
طلب:
```json
{ "phone": "0944123456", "password": "••••••" }
```
رد (`data`):
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "user": { "id": "1", "name": "محمد أحمد", "phone": "0944123456", "role": "user", "location": "حلب - الفرقان", "prices_count": 45, "ratings_count": 56, "reports_count": 3, "is_active": true }
}
```

### POST /auth/register
طلب:
```json
{ "name": "محمد أحمد", "phone": "0944123456", "password": "••••••", "password_confirmation": "••••••", "sector": "حلب" }
```
رد: نفس شكل `/auth/login`.

### POST /auth/admin/login
طلب: `{ "username": "admin@waffir.sy", "password": "••••••" }` (يقبل هاتف أو بريد)
رد: نفس شكل `/auth/login` مع `role: "admin"`.

### POST /auth/logout
بدون body، يُبطل الـ refresh token في الخادم.

### GET /auth/me
يُستخدم عند فتح التطبيق لاستعادة الجلسة تلقائياً (auto-login) إن وُجد توكن محفوظ.
رد: نفس شكل `user` أعلاه.

### PUT /auth/profile
طلب: `{ "name": "الاسم الجديد" }` → رد: كائن `user` محدّث.

### POST /auth/refresh
طلب: `{ "refresh_token": "..." }` → رد: `{ "access_token": "...", "refresh_token": "..." }`
(يُستدعى تلقائياً من `ApiClient` عند انتهاء صلاحية التوكن، عبر Interceptor.)

### POST /auth/forgot-password
طلب: `{ "phone": "0944123456" }` → يرسل رمز/رابط استعادة عبر SMS.

### PUT /auth/change-password
طلب: `{ "current_password": "...", "new_password": "...", "new_password_confirmation": "..." }`

---

## 3. المنتجات (Products)

نموذج `ProductModel`:
```json
{
  "id": "1", "name": "رز أبيض", "category": "حبوب",
  "official_price": 12000, "real_price": 15500, "avg_price": 15200,
  "unit": "كغ", "prices_count": 4, "change_percent": 29, "is_price_up": true
}
```

- **GET /products?search=&category=&page=&per_page=** → قائمة `ProductModel` (paginated)
- **GET /products/{id}** → `ProductModel` واحد
- **GET /products/{id}/prices** → قائمة `PriceEntry` الخاصة بهذا المنتج
- **POST /products** *(إداري)* → `{ "name": "...", "category": "...", "unit": "..." }`
- **DELETE /products/{id}** *(إداري)*

`change_percent` و `is_price_up` يُفضَّل حسابهما في الخادم بمقارنة `real_price`
مع `official_price` بدل حسابهما في التطبيق.

---

## 4. المتاجر (Stores)

نموذج `StoreModel`:
```json
{
  "id": "1", "name": "محل الأمانة", "address": "شارع الفرقان الرئيسي",
  "area": "الفرقان", "sector": "حلب", "is_verified": true, "prices_count": 24
}
```

- **GET /stores?search=&sector=&page=&per_page=**
- **GET /stores/{id}**
- **POST /stores** → `{ "name", "address", "area", "sector" }` (يمكن استخدامه من مستخدم عادي كـ"اقتراح متجر جديد" بحالة `pending` حتى يوثّقه الإداري)
- **PATCH /stores/{id}/verify** *(إداري)* → `{ "is_verified": true }`
- **DELETE /stores/{id}** *(إداري)*

---

## 5. الأسعار المُقدَّمة من المستخدمين (Prices)

نموذج `PriceEntry`:
```json
{
  "id": "1", "product_name": "زيت زيتون فلسطين", "store_name": "سوبر ماركت النور",
  "store_area": "الميدان", "price": 45000, "unit": "لتر", "quantity": 1,
  "brand": "فلسطين", "submitted_by": "محمد أحمد",
  "submitted_at": "2026-05-17T10:00:00Z",
  "thumbs_up": 12, "thumbs_down": 2, "total_ratings": 14, "status": "pending"
}
```
`status` من: `pending` | `approved` | `rejected`.

- **GET /prices?status=&page=&per_page=** *(مراجعة إدارية)*
- **POST /prices** → إرسال سعر من المستخدم (شاشة "إضافة سعر"):
  ```json
  { "product_id": "1", "store_id": "2", "price": 15500, "unit": "كغ", "quantity": 1, "brand": "العروس" }
  ```
- **POST /prices/{id}/vote** → `{ "is_up": true }` (إعجاب/عدم إعجاب من مستخدم آخر)
- **PATCH /prices/{id}/approve** أو **/prices/{id}/reject** *(إداري)*

---

## 6. البلاغات (Reports)

نموذج `ReportModel`:
```json
{
  "id": "1", "product_name": "زيت زيتون فلسطين", "store_name": "سوبر ماركت النور",
  "user_name": "أحمد محمود", "type": "wrong_price",
  "reported_at": "2026-05-17T14:30:00Z", "status": "pending"
}
```
`type` من: `wrong_price` | `outdated` | `duplicate` | `other`.
`status` من: `pending` | `reviewed` | `resolved`.

- **GET /reports?status=&page=&per_page=** *(إداري)*
- **POST /reports** → `{ "price_entry_id": "1", "type": "wrong_price", "note": "..." }`
- **PATCH /reports/{id}** *(إداري)* → `{ "status": "resolved" }`

---

## 7. إدارة المستخدمين (Admin Users)

- **GET /admin/users?search=&status=&page=&per_page=** → قائمة `UserModel` (`status`: active | blocked)
- **PATCH /admin/users/{id}/block** أو **/admin/users/{id}/unblock**
- **PATCH /admin/users/{id}/role** → `{ "role": "admin" }`

---

## 8. بيانات مرجعية إدارية بسيطة

### الأسعار الرسمية (`OfficialPrice`)
```json
{ "id": "1", "product_name": "زيت زيتون فلسطين", "unit": "لتر", "quantity": 1, "price": 43000, "updated_at": "2026-05-15T00:00:00Z" }
```
- **GET /official-prices?search=**
- **POST /official-prices** → `{ "product_name", "unit", "quantity", "price" }`

### الوحدات (`UnitModel`)
```json
{ "id": "1", "name": "كيلوغرام", "usage_count": 456 }
```
- **GET /units** — **POST /units** `{ "name" }` — **DELETE /units/{id}**

### العلامات التجارية (`BrandModel`)
```json
{ "id": "1", "name": "فلسطين", "products_count": 45 }
```
- **GET /brands** — **POST /brands** `{ "name" }` — **DELETE /brands/{id}**

### المواقع والقطاعات (`LocationModel`)
```json
{ "id": "1", "sector": "دمشق", "area": "الميدان", "landmark": "شارع بغداد", "stores_count": 45 }
```
- **GET /locations?search=** — **POST /locations** `{ "sector", "area", "landmark" }`

---

## 9. لوحة الإحصائيات الإدارية

### GET /admin/dashboard-stats
```json
{
  "totalUsers": 1248, "totalProducts": 856, "totalStores": 324,
  "totalPrices": 4562, "totalReports": 89,
  "usersGrowth": 12, "productsGrowth": 8, "storesGrowth": 5, "pricesGrowth": 18
}
```

### GET /admin/recent-activity
```json
[
  { "type": "price", "text": "تم إضافة سعر جديد لمنتج زيت زيتون فلسطين", "time": "منذ 5 دقائق", "color": "blue" }
]
```
`type`: price | report | user | store | official. `color`: blue | red | green | purple.

---

## 10. رفع الملفات

`ApiClient.upload()` جاهز لأي endpoint يستقبل `multipart/form-data` (مثلاً صورة
إيصال عند إرسال سعر). لا يوجد endpoint فعلي مطلوب بعد — إن احتجتم صور إثبات
للأسعار، أضيفوا حقل `receipt_image` إلى `POST /prices` كـ multipart وأخبرونا
لنفعّله في التطبيق.

---

## 11. خريطة سريعة: أين يقع كل شيء في كود Flutter

| الطبقة | الملف |
|---|---|
| عميل HTTP + إدارة التوكن | `lib/core/network/api_client.dart` |
| شكل الأخطاء الموحّد | `lib/core/network/api_exception.dart` |
| شكل الرد الموحّد + Pagination | `lib/core/network/api_response.dart` |
| كل الـ Services (منتجات، متاجر، أسعار...) | `lib/core/network/services/*.dart` |
| خدمة المصادقة | `lib/features/auth/data/auth_service.dart` |
| الحالة العامة + تبديل mock/real | `lib/core/utils/app_provider.dart` |
| مفتاح mock/real ورابط الـ API | `lib/core/config/app_config.dart` |
| كل الـ Models وتحويل JSON | `lib/models/models.dart` |

أي عدم تطابق بين هذا الملف والكود الفعلي، اعتمدوا الكود كمرجع نهائي (خصوصاً
دوال `fromJson`/`toJson` في `models.dart`) وأخبرونا لتحديث هذا الملف.
