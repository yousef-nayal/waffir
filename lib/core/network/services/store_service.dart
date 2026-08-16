import '../../../models/models.dart';
import '../api_client.dart';
import '../api_response.dart';

/// خدمة المتاجر — راجع API_DOCUMENTATION.md → قسم "المتاجر"
class StoreService {
  final ApiClient _api;
  StoreService({ApiClient? api}) : _api = api ?? ApiClient();

  /// GET /stores?search=&sector=&page=&per_page=
  Future<ApiResponse<List<StoreModel>>> getStores({
    String? search,
    String? sector,
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<ApiResponse<List<StoreModel>>>(
      '/stores',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (sector != null && sector != 'الكل') 'sector': sector,
        'page': page,
        'per_page': perPage,
      },
      fromJson: (json) => ApiResponse.fromJson(
        json as Map<String, dynamic>,
        (data) => (data as List).map((e) => StoreModel.fromJson(e)).toList(),
      ),
    );
  }

  /// GET /stores/{id}
  Future<StoreModel> getStoreById(String id) {
    return _api.get<StoreModel>(
      '/stores/$id',
      fromJson: (json) =>
          StoreModel.fromJson((json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ إصلاح جوهري — كانت هذه الدالة تستقبل area/sector كنصين حرّين
  // وترسلهما مباشرة، رغم أن عمود Store.location_id في قاعدة البيانات
  // الفعلي مفتاح أجنبي إلزامي يشير لصف محدد في جدول Location، لا نص حر.
  // إرسال نص حر كان سيمنع الخادم من ربط المتجر بموقعه الصحيح، أو كان
  // سيضطره لعمل مطابقة نصية هشة عرضة للأخطاء الإملائية والتكرار.
  //
  // الآن تستقبل locationId (معرّف حقيقي، يُحسَب في الشاشة عبر
  // CatalogProvider.locationIdForArea بمطابقة اسم الحي المختار مع قائمة
  // المواقع الفعلية المُحمَّلة من الخادم GET /locations) وترسله مباشرة.
  // ══════════════════════════════════════════════════════════════════
  Future<StoreModel> createStore({
    required String locationId,
    required String name,
    required String address,
  }) {
    return _api.post<StoreModel>(
      '/stores',
      data: {
        'location_id': locationId,
        'name': name,
        'address': address,
      },
      fromJson: (json) =>
          StoreModel.fromJson((json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  /// PATCH /stores/{id}/verify — (استخدام إداري) توثيق متجر
  Future<void> verifyStore(String id, {required bool verified}) {
    return _api.patch<void>('/stores/$id/verify', data: {'is_verified': verified});
  }

  /// DELETE /stores/{id} — (استخدام إداري)
  Future<void> deleteStore(String id) {
    return _api.delete<void>('/stores/$id');
  }
}