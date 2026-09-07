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

  /// POST /stores — إضافة متجر جديد (يمكن استخدامها من المستخدم كطلب "اقتراح متجر")
  Future<StoreModel> createStore({
    required String name,
    required String address,
    required String area,
    required String sector,
  }) {
    return _api.post<StoreModel>(
      '/stores',
      data: {
        'name': name,
        'address': address,
        'area': area,
        'sector': sector,
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
