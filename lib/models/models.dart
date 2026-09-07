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
      role: json['role'] as String? ?? 'user',
      location: json['location'] as String? ?? '',
      pricesCount: json['prices_count'] as int? ?? 0,
      ratingsCount: json['ratings_count'] as int? ?? 0,
      reportsCount: json['reports_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
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
// ✅ PriceEntry — أُضيف productId/storeId (كانا مفقودَين تماماً). قبل هذا
// الإصلاح كان toJson() يرسل أسماء المنتج/المتجر بدل الـ IDs الحقيقية
// (خطأ فادح كان سيمنع PriceService.submitPrice من العمل مع أي backend
// حقيقي يتوقع معرّفات). الآن الحقل مطلوب من واجهة "إضافة سعر" مباشرة.
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
  final double quantity;
  final String brand;
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
    required this.quantity,
    this.brand = '',
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
      quantity: _toDouble(json['quantity']),
      brand: json['brand'] as String? ?? '',
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

  /// ✅ إصلاح: كان يرسل productName/storeName بدل productId/storeId فعلياً.
  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'store_id': storeId,
        'price': price,
        'unit': unit,
        'quantity': quantity,
        if (brand.isNotEmpty) 'brand': brand,
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
      quantity: quantity,
      brand: brand,
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
  final DateTime reportedAt;
  final String status; // 'pending' | 'reviewed' | 'resolved'

  ReportModel({
    required this.id,
    required this.productName,
    required this.storeName,
    this.storeArea = '',
    required this.userName,
    required this.type,
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
        reportedAt: reportedAt,
        status: status ?? this.status,
      );
}

class OfficialPrice {
  final String id;
  final String productName;
  final String unit;
  final double quantity;
  final double price;
  final DateTime updatedAt;

  OfficialPrice({
    required this.id,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.updatedAt,
  });

  factory OfficialPrice.fromJson(Map<String, dynamic> json) {
    return OfficialPrice(
      id: (json['id'] ?? '').toString(),
      productName: json['product_name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      quantity: _toDouble(json['quantity']),
      price: _toDouble(json['price']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_name': productName,
        'unit': unit,
        'quantity': quantity,
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