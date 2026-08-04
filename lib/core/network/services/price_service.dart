import '../../../models/models.dart';
import '../api_client.dart';
import '../api_response.dart';

/// خدمة الأسعار المُقدَّمة من المستخدمين — راجع API_DOCUMENTATION.md → "الأسعار"
class PriceService {
  final ApiClient _api;
  PriceService({ApiClient? api}) : _api = api ?? ApiClient();

  /// GET /prices?status=&page=&per_page= — (مراجعة الإدارة)
  Future<ApiResponse<List<PriceEntry>>> getPrices({
    String? status,
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<ApiResponse<List<PriceEntry>>>(
      '/prices',
      queryParameters: {
        if (status != null && status != 'الكل') 'status': status,
        'page': page,
        'per_page': perPage,
      },
      fromJson: (json) => ApiResponse.fromJson(
        json as Map<String, dynamic>,
        (data) => (data as List).map((e) => PriceEntry.fromJson(e)).toList(),
      ),
    );
  }

  /// POST /prices — إرسال سعر جديد من مستخدم (شاشة إضافة سعر)
  Future<PriceEntry> submitPrice({
    required String productId,
    required String storeId,
    required double price,
    required String unit,
    required double quantity,
    String? brand,
  }) {
    return _api.post<PriceEntry>(
      '/prices',
      data: {
        'product_id': productId,
        'store_id': storeId,
        'price': price,
        'unit': unit,
        'quantity': quantity,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
      },
      fromJson: (json) =>
          PriceEntry.fromJson((json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  /// POST /prices/{id}/vote — تقييم إعجاب/عدم إعجاب لسعر
  Future<void> votePrice(String id, {required bool isUp}) {
    return _api.post<void>('/prices/$id/vote', data: {'is_up': isUp});
  }

  /// PATCH /prices/{id}/approve أو /reject — (استخدام إداري)
  Future<void> reviewPrice(String id, {required bool approve}) {
    final action = approve ? 'approve' : 'reject';
    return _api.patch<void>('/prices/$id/$action');
  }
}
