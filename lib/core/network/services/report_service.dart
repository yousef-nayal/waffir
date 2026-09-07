import '../../../models/models.dart';
import '../api_client.dart';
import '../api_response.dart';

/// خدمة البلاغات — راجع API_DOCUMENTATION.md → "البلاغات"
class ReportService {
  final ApiClient _api;
  ReportService({ApiClient? api}) : _api = api ?? ApiClient();

  /// GET /reports?status=&page=&per_page=
  Future<ApiResponse<List<ReportModel>>> getReports({
    String? status,
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<ApiResponse<List<ReportModel>>>(
      '/reports',
      queryParameters: {
        if (status != null && status != 'الكل') 'status': status,
        'page': page,
        'per_page': perPage,
      },
      fromJson: (json) => ApiResponse.fromJson(
        json as Map<String, dynamic>,
        (data) => (data as List).map((e) => ReportModel.fromJson(e)).toList(),
      ),
    );
  }

  /// POST /reports — إرسال بلاغ عن سعر من مستخدم
  Future<ReportModel> submitReport({
    required String priceEntryId,
    required String type, // wrong_price | outdated | duplicate | other
    String? note,
  }) {
    return _api.post<ReportModel>(
      '/reports',
      data: {
        'price_entry_id': priceEntryId,
        'type': type,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      fromJson: (json) =>
          ReportModel.fromJson((json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  /// PATCH /reports/{id} — (استخدام إداري) تحديث حالة البلاغ
  Future<void> updateReportStatus(String id, String status) {
    return _api.patch<void>('/reports/$id', data: {'status': status});
  }
}
