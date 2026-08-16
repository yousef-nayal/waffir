class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String location;
  final int pricesCount;
  final int ratingsCount;
  final int reportsCount;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.role = 'user',
    this.location = '',
    this.pricesCount = 0,
    this.ratingsCount = 0,
    this.reportsCount = 0,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: _parseRole(json['role']),
      location: json['location'] as String? ?? '',
      pricesCount: json['prices_count'] as int? ?? 0,
      ratingsCount: json['ratings_count'] as int? ?? 0,
      reportsCount: json['reports_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ✅ إصلاح جوهري — العمود الفعلي role في قاعدة البيانات من نوع tinyint
  // مقيّد بالقيم (0, 1, 2)، بينما كان الكود القديم يفترض دائماً أن الخادم
  // يُرجع نصاً جاهزاً عبر `json['role'] as String?` — أي أن وصول أي قيمة
  // رقمية من الـ backend (وهو المتوقع فعلياً بما أن العمود tinyint) كان
  // سيرمي استثناءً فورياً ويعطّل تحليل استجابة تسجيل الدخول بالكامل.
  //
  // هذه الدالة تتعامل مع الحالتين بأمان: رقم مباشر (0/1/2)، أو نص جاهز
  // ('admin'/'user') في حال كانت طبقة الـ API تُرجعه مُترجَماً مسبقاً.
  //
  // الترميز المعتمد داخلياً (بانتظار تأكيد صريح من مطوّر الـ backend):
  //   0 = مدير عام (super admin) → يُعامَل كـ"admin" داخل التطبيق
  //   1 = مدير (admin)           → يُعامَل كـ"admin" داخل التطبيق
  //   2 = مستخدم عادي (user)     → "user"
  // كلا 0 و1 يُمنحان صلاحية الدخول للوحة الإدارة لأن التطبيق حالياً لا
  // يفرّق بين مستويين إداريين مختلفين في الواجهة.
  // ══════════════════════════════════════════════════════════════════════
  static String _parseRole(dynamic raw) {
    if (raw == null) return 'user';
    if (raw is int) return raw == 2 ? 'user' : 'admin';
    if (raw is String) {
      final asInt = int.tryParse(raw);
      if (asInt != null) return asInt == 2 ? 'user' : 'admin';
      return raw; // نص جاهز مثل 'admin' أو 'user'
    }
    return 'user';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'location': location,
        'prices_count': pricesCount,
        'ratings_count': ratingsCount,
        'reports_count': reportsCount,
        'is_active': isActive,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? location,
    int? pricesCount,
    int? ratingsCount,
    int? reportsCount,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      location: location ?? this.location,
      pricesCount: pricesCount ?? this.pricesCount,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      reportsCount: reportsCount ?? this.reportsCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double officialPrice;
  final double realPrice;
  final double avgPrice;
  final String unit;
  final int pricesCount;
  final double changePercent;
  final bool isPriceUp;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.officialPrice,
    required this.realPrice,
    required this.avgPrice,
    required this.unit,
    required this.pricesCount,
    required this.changePercent,
    required this.isPriceUp,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      officialPrice: _toDouble(json['official_price']),
      realPrice: _toDouble(json['real_price']),
      avgPrice: _toDouble(json['avg_price']),
      unit: json['unit'] as String? ?? 'كغ',
      pricesCount: json['prices_count'] as int? ?? 0,
      changePercent: _toDouble(json['change_percent']),
      isPriceUp: json['is_price_up'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'official_price': officialPrice,
        'real_price': realPrice,
        'avg_price': avgPrice,
        'unit': unit,
        'prices_count': pricesCount,
        'change_percent': changePercent,
        'is_price_up': isPriceUp,
      };
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class StoreModel {
  final String id;
  final String name;
  final String address;
  final String area;
  final String sector;
  final bool isVerified;
  final int pricesCount;

  StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.sector,
    this.isVerified = false,
    this.pricesCount = 0,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      area: json['area'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      pricesCount: json['prices_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'area': area,
        'sector': sector,
        'is_verified': isVerified,
        'prices_count': pricesCount,
      };

  StoreModel copyWith({
    String? id,
    String? name,
    String? address,
    String? area,
    String? sector,
    bool? isVerified,
    int? pricesCount,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      area: area ?? this.area,
      sector: sector ?? this.sector,
      isVerified: isVerified ?? this.isVerified,
      pricesCount: pricesCount ?? this.pricesCount,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ PriceEntry — أُضيف unitId/brandId (معرّفان حقيقيان اختياريان يطابقان
// unit_id/brand_id في مخطط قاعدة البيانات الفعلي). الحقلان unit/brand
// النصيان بقيا كما هما تماماً لعرض الاسم مباشرة في الواجهة (denormalized)،
// بلا أي تغيير في شكل أي بطاقة سعر. الفرق الوحيد: عند القراءة من الخادم،
// إن أرسل unit_id/brand_id يُحفظان هنا أيضاً لاستخدامهما لاحقاً (مثلاً عند
// تعديل سعر موجود مستقبلاً)، وعند الإرسال الفعلي للسعر الجديد
// (PriceService.submitPrice) تُستخدم هذه المعرّفات الحقيقية بدل النصوص.
// ══════════════════════════════════════════════════════════════════════════════
class PriceEntry {
  final String id;
  final String productId;
  final String productName;
  final String storeId;
  final String storeName;
  final String storeArea;
  final double price;
  final String unit;
  final String? unitId;
  final double quantity;
  final String brand;
  final String? brandId;
  final String submittedBy;
  final DateTime submittedAt;
  final int thumbsUp;
  final int thumbsDown;
  final int totalRatings;
  final String status;

  PriceEntry({
    required this.id,
    this.productId = '',
    required this.productName,
    this.storeId = '',
    required this.storeName,
    required this.storeArea,
    required this.price,
    required this.unit,
    this.unitId,
    required this.quantity,
    this.brand = '',
    this.brandId,
    required this.submittedBy,
    required this.submittedAt,
    this.thumbsUp = 0,
    this.thumbsDown = 0,
    this.totalRatings = 0,
    this.status = 'pending',
  });

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    return PriceEntry(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: json['product_name'] as String? ?? '',
      storeId: (json['store_id'] ?? '').toString(),
      storeName: json['store_name'] as String? ?? '',
      storeArea: json['store_area'] as String? ?? '',
      price: _toDouble(json['price']),
      unit: json['unit'] as String? ?? '',
      unitId: json['unit_id'] != null ? json['unit_id'].toString() : null,
      // ✅ إصلاح تسمية — عمود قاعدة البيانات الفعلي اسمه amount وليس
      // quantity. نقرأ amount أولاً، ونتراجع إلى quantity فقط توافقاً مع
      // بيانات العرض التجريبي (MockData) التي بقيت بالاسم القديم.
      quantity: _toDouble(json['amount'] ?? json['quantity']),
      brand: json['brand'] as String? ?? '',
      brandId: json['brand_id'] != null ? json['brand_id'].toString() : null,
      submittedBy: json['submitted_by'] as String? ?? '',
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : DateTime.now(),
      thumbsUp: json['thumbs_up'] as int? ?? 0,
      thumbsDown: json['thumbs_down'] as int? ?? 0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// ✅ محدَّث — يرسل amount (لا quantity) وunit_id/brand_id الحقيقيين إن
  /// وُجدا، بدل unit/brand النصيين. ملاحظة: هذا الـtoJson غير مستخدَم حالياً
  /// في مسار إرسال سعر جديد (PriceService.submitPrice يبني حمولته يدوياً)،
  /// لكنه أُصلح لتفادي أي استخدام مستقبلي خاطئ له.
  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'store_id': storeId,
        'price': price,
        'amount': quantity,
        if (unitId != null && unitId!.isNotEmpty) 'unit_id': unitId,
        if (brandId != null && brandId!.isNotEmpty) 'brand_id': brandId,
      };

  PriceEntry copyWith({
    int? thumbsUp,
    int? thumbsDown,
    int? totalRatings,
    String? status,
  }) {
    return PriceEntry(
      id: id,
      productId: productId,
      productName: productName,
      storeId: storeId,
      storeName: storeName,
      storeArea: storeArea,
      price: price,
      unit: unit,
      unitId: unitId,
      quantity: quantity,
      brand: brand,
      brandId: brandId,
      submittedBy: submittedBy,
      submittedAt: submittedAt,
      thumbsUp: thumbsUp ?? this.thumbsUp,
      thumbsDown: thumbsDown ?? this.thumbsDown,
      totalRatings: totalRatings ?? this.totalRatings,
      status: status ?? this.status,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ إضافة fromJson لكل الـ models التالية (كانت ناقصة)
// ══════════════════════════════════════════════════════════════════════════════

class ReportModel {
  final String id;
  final String productName;
  final String storeName;
  // ✅ جديد — حي المتجر المرتبط بالبلاغ. أُضيف خصيصاً ليتيح لشاشة "إدارة
  // البلاغات" في لوحة الإدارة الفلترة حسب الكتلة الإدارية عبر
  // AleppoBlocks.blockOfArea(r.storeArea)، بنفس الطريقة المستخدمة أصلاً في
  // PriceEntry.storeArea. اختياري تماماً: أي بلاغ قديم من الخادم بلا هذا
  // الحقل يبقى يعمل بشكل طبيعي (يظهر فقط ضمن "الكل" ولا يظهر تحت أي كتلة).
  final String storeArea;
  final String userName;
  final String type; // 'wrong_price' | 'outdated' | 'duplicate' | 'other'
  // ✅ جديد — يطابق عمود description الفعلي في جدول Report (كان الفرونت
  // يرسل هذا النص سابقاً تحت مفتاح 'note' الخاطئ ولا يقرأه إطلاقاً عند
  // الاستقبال). غير مستخدَم حالياً في أي واجهة عرض — إضافته هنا فقط لضمان
  // عدم فقدانه صامتاً عند القراءة من الخادم مستقبلاً، بلا أي تغيير مرئي.
  final String? description;
  final DateTime reportedAt;
  final String status; // 'pending' | 'reviewed' | 'resolved'

  ReportModel({
    required this.id,
    required this.productName,
    required this.storeName,
    this.storeArea = '',
    required this.userName,
    required this.type,
    this.description,
    required this.reportedAt,
    this.status = 'pending',
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: (json['id'] ?? '').toString(),
      productName: json['product_name'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      storeArea: json['store_area'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      description: json['description'] as String?,
      reportedAt: json['reported_at'] != null
          ? DateTime.parse(json['reported_at'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_name': productName,
        'store_name': storeName,
        'store_area': storeArea,
        'user_name': userName,
        'type': type,
        if (description != null) 'description': description,
        'reported_at': reportedAt.toIso8601String(),
        'status': status,
      };

  ReportModel copyWith({String? status}) => ReportModel(
        id: id,
        productName: productName,
        storeName: storeName,
        storeArea: storeArea,
        userName: userName,
        type: type,
        description: description,
        reportedAt: reportedAt,
        status: status ?? this.status,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ OfficialPrice — أُضيف productId/unitId (معرّفان حقيقيان اختياريان
// يطابقان product_id/unit_id في مخطط قاعدة البيانات الفعلي). productName/
// unit النصيان بقيا كما هما تماماً لعرض الاسم مباشرة في كل شاشات العرض
// (لا تغيير مرئي إطلاقاً)، لكن أصبح بالإمكان الآن إرسال معرّفات حقيقية
// عند إضافة سعر رسمي جديد من لوحة الإدارة بدل نص اسم منتج حر غير مرتبط
// فعلياً بجدول Product.
// ══════════════════════════════════════════════════════════════════════════════
class OfficialPrice {
  final String id;
  final String? productId;
  final String productName;
  final String? unitId;
  final String unit;
  final double quantity;
  final double price;
  final DateTime updatedAt;

  OfficialPrice({
    required this.id,
    this.productId,
    required this.productName,
    this.unitId,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.updatedAt,
  });

  factory OfficialPrice.fromJson(Map<String, dynamic> json) {
    return OfficialPrice(
      id: (json['id'] ?? '').toString(),
      productId:
          json['product_id'] != null ? json['product_id'].toString() : null,
      productName: json['product_name'] as String? ?? '',
      unitId: json['unit_id'] != null ? json['unit_id'].toString() : null,
      unit: json['unit'] as String? ?? '',
      // ✅ إصلاح تسمية — عمود قاعدة البيانات الفعلي اسمه amount وليس
      // quantity، بنفس منطق PriceEntry أعلاه.
      quantity: _toDouble(json['amount'] ?? json['quantity']),
      price: _toDouble(json['price']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (productId != null) 'product_id': productId,
        if (unitId != null) 'unit_id': unitId,
        'product_name': productName,
        'unit': unit,
        'amount': quantity,
        'price': price,
        'updated_at': updatedAt.toIso8601String(),
      };
}
// ══════════════════════════════════════════════════════════════════════════════
// ✅ جديد — سجل تغييرات السعر الرسمي عبر الزمن. تُستخدم في شاشة
// OfficialPriceHistoryScreen التي تُفتح عند النقر على أي مادة في شاشة
// "الأسعار الرسمية"، وتعرض متى تغيّر سعر هذه المادة وبأي قيمة في كل مرة.
// المصدر المتوقع من الـ backend: GET /official-prices/{id}/history
// ══════════════════════════════════════════════════════════════════════════════
class OfficialPriceHistoryEntry {
  final String id;
  final double price;
  final DateTime changedAt;

  OfficialPriceHistoryEntry({
    required this.id,
    required this.price,
    required this.changedAt,
  });

  factory OfficialPriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OfficialPriceHistoryEntry(
      id: (json['id'] ?? '').toString(),
      price: _toDouble(json['price']),
      changedAt: json['changed_at'] != null
          ? DateTime.parse(json['changed_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'price': price,
        'changed_at': changedAt.toIso8601String(),
      };
}

class UnitModel {
  final String id;
  final String name;
  final int usageCount;

  UnitModel({required this.id, required this.name, required this.usageCount});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      usageCount: json['usage_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'usage_count': usageCount,
      };
}

class BrandModel {
  final String id;
  final String name;
  final int productsCount;

  BrandModel(
      {required this.id, required this.name, required this.productsCount});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      productsCount: json['products_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'products_count': productsCount,
      };
}

class LocationModel {
  final String id;
  final String sector;
  final String area;
  final String landmark;
  final int storesCount;

  LocationModel({
    required this.id,
    required this.sector,
    required this.area,
    required this.landmark,
    required this.storesCount,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: (json['id'] ?? '').toString(),
      sector: json['sector'] as String? ?? '',
      area: json['area'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      storesCount: json['stores_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sector': sector,
        'area': area,
        'landmark': landmark,
        'stores_count': storesCount,
      };
}