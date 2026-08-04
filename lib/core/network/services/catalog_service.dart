import '../../../models/models.dart';
import '../api_client.dart';

/// خدمة موحّدة لكل "بيانات المرجع" الإدارية البسيطة:
/// الأسعار الرسمية، الوحدات، العلامات التجارية، والمواقع/القطاعات.
/// كلها CRUD بسيط بنفس الشكل، لذا جُمعت في خدمة واحدة لتقليل التكرار.
/// راجع API_DOCUMENTATION.md → الأقسام المقابلة لكل واحدة.
class CatalogService {
  final ApiClient _api;
  CatalogService({ApiClient? api}) : _api = api ?? ApiClient();

  // ── الأسعار الرسمية ────────────────────────────────────────────────
  Future<List<OfficialPrice>> getOfficialPrices({String? search}) {
    return _api.get<List<OfficialPrice>>(
      '/official-prices',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search
      },
      fromJson: (json) {
        final list = (json as Map<String, dynamic>)['data'] as List? ?? [];
        return list.map((e) => OfficialPrice.fromJson(e)).toList();
      },
    );
  }

  Future<OfficialPrice> createOfficialPrice({
    required String productName,
    required String unit,
    required double quantity,
    required double price,
  }) {
    return _api.post<OfficialPrice>(
      '/official-prices',
      data: {
        'product_name': productName,
        'unit': unit,
        'quantity': quantity,
        'price': price,
      },
      fromJson: (json) => OfficialPrice.fromJson(
          (json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  /// GET /official-prices/{id}/history — ✅ جديد
  /// سجل تغييرات السعر الرسمي لمادة معيّنة عبر الزمن، مرتباً حسب تاريخ
  /// التغيير. يُتوقَّع من الـ backend إرجاع مصفوفة بهذا الشكل:
  /// { "success": true, "data": [ { "id": "...", "price": 43000,
  ///   "changed_at": "2026-05-15T00:00:00Z" }, ... ] }
  Future<List<OfficialPriceHistoryEntry>> getOfficialPriceHistory(
      String officialPriceId) {
    return _api.get<List<OfficialPriceHistoryEntry>>(
      '/official-prices/$officialPriceId/history',
      fromJson: (json) {
        final list = (json as Map<String, dynamic>)['data'] as List? ?? [];
        return list.map((e) => OfficialPriceHistoryEntry.fromJson(e)).toList();
      },
    );
  }

  // ── الوحدات ────────────────────────────────────────────────────────
  Future<List<UnitModel>> getUnits() {
    return _api.get<List<UnitModel>>(
      '/units',
      fromJson: (json) {
        final list = (json as Map<String, dynamic>)['data'] as List? ?? [];
        return list.map((e) => UnitModel.fromJson(e)).toList();
      },
    );
  }

  Future<UnitModel> createUnit(String name) {
    return _api.post<UnitModel>(
      '/units',
      data: {'name': name},
      fromJson: (json) =>
          UnitModel.fromJson((json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  Future<void> deleteUnit(String id) => _api.delete<void>('/units/$id');

  // ── العلامات التجارية ──────────────────────────────────────────────
  Future<List<BrandModel>> getBrands() {
    return _api.get<List<BrandModel>>(
      '/brands',
      fromJson: (json) {
        final list = (json as Map<String, dynamic>)['data'] as List? ?? [];
        return list.map((e) => BrandModel.fromJson(e)).toList();
      },
    );
  }

  Future<BrandModel> createBrand(String name) {
    return _api.post<BrandModel>(
      '/brands',
      data: {'name': name},
      fromJson: (json) =>
          BrandModel.fromJson((json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  Future<void> deleteBrand(String id) => _api.delete<void>('/brands/$id');

  // ── المواقع والقطاعات ──────────────────────────────────────────────
  Future<List<LocationModel>> getLocations({String? search}) {
    return _api.get<List<LocationModel>>(
      '/locations',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search
      },
      fromJson: (json) {
        final list = (json as Map<String, dynamic>)['data'] as List? ?? [];
        return list.map((e) => LocationModel.fromJson(e)).toList();
      },
    );
  }

  Future<LocationModel> createLocation({
    required String sector,
    required String area,
    required String landmark,
  }) {
    return _api.post<LocationModel>(
      '/locations',
      data: {'sector': sector, 'area': area, 'landmark': landmark},
      fromJson: (json) => LocationModel.fromJson(
          (json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  // ── لوحة الإحصائيات الإدارية ───────────────────────────────────────
  /// GET /admin/dashboard-stats
  Future<Map<String, dynamic>> getDashboardStats() {
    return _api.get<Map<String, dynamic>>(
      '/admin/dashboard-stats',
      fromJson: (json) => (json as Map<String, dynamic>)['data'] ?? json,
    );
  }

  /// GET /admin/recent-activity
  Future<List<Map<String, dynamic>>> getRecentActivity() {
    return _api.get<List<Map<String, dynamic>>>(
      '/admin/recent-activity',
      fromJson: (json) {
        final list = (json as Map<String, dynamic>)['data'] as List? ?? [];
        return list.cast<Map<String, dynamic>>();
      },
    );
  }
}
