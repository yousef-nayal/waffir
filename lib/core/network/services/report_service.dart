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
  ///
  /// ✅ إصلاح تسمية — كان يُرسَل تحت مفتاح 'note' بينما العمود الفعلي في
  /// جدول Report اسمه description (راجع مخطط قاعدة البيانات). اسم المعامل
  /// [note] بقي كما هو داخل الكود (تفادياً لتغيير أي شاشة تستدعيه)، والتغيير
  /// اقتصر على مفتاح الحمولة المُرسَلة فعلياً عبر الشبكة فقط.
  ///
  /// ✅ إصلاح جوهري إضافي — [type] يجب أن يكون إحدى القيم الثلاث الحصرية
  /// المعرَّفة في ReportType (راجع models.dart)، لأن عمود Report.type مقيّد
  /// بـ CHECK في قاعدة البيانات الفعلية بثلاث قيم عربية فقط، لا 4 مفاتيح
  /// إنجليزية كما كان الحال سابقاً. كما لا يُرسَل description إطلاقاً إلا
  /// عندما type == ReportType.wrongInfo، مطابقةً لقيد الـ CHECK الثاني:
  /// (type = 'معلومات غير صحيحة' OR description IS NULL).
  Future<ReportModel> submitReport({
    required String priceEntryId,
    required String type, // إحدى قيم ReportType الثلاث فقط
    String? note,
  }) {
    final canSendDescription = ReportType.allowsDescription(type);
    return _api.post<ReportModel>(
      '/reports',
      data: {
        'price_entry_id': priceEntryId,
        'type': type,
        if (canSendDescription && note != null && note.isNotEmpty)
          'description': note,
      },
      fromJson: (json) =>
          ReportModel.fromJson((json as Map<String, dynamic>)['data'] ?? json),
    );
  }

  /// DELETE /reports/{id} — ✅ جديد — (استخدام إداري) حذف بلاغ نهائياً.
  /// حلّت محل updateReportStatus السابقة: جدول Report في قاعدة البيانات
  /// الفعلية لا يحتوي عمود status إطلاقاً (راجع Waffir_Database.txt)، بينما
  /// مخطط حالات الاستخدام يُدرج "حذف البلاغ" صراحة كالإجراء الوحيد المطلوب
  /// ضمن "إدارة البلاغات" — فأصبح الحذف هو مسار المراجعة الإدارية الفعلي.
  Future<void> deleteReport(String id) {
    return _api.delete<void>('/reports/$id');
  }
}