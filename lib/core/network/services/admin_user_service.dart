import '../../../models/models.dart';
import '../api_client.dart';
import '../api_response.dart';

/// خدمة إدارة المستخدمين — راجع API_DOCUMENTATION.md → "إدارة المستخدمين"
class AdminUserService {
  final ApiClient _api;
  AdminUserService({ApiClient? api}) : _api = api ?? ApiClient();

  /// GET /admin/users?search=&status=&page=&per_page=
  Future<ApiResponse<List<UserModel>>> getUsers({
    String? search,
    String? status, // active | blocked
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get<ApiResponse<List<UserModel>>>(
      '/admin/users',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        'page': page,
        'per_page': perPage,
      },
      fromJson: (json) => ApiResponse.fromJson(
        json as Map<String, dynamic>,
        (data) => (data as List).map((e) => UserModel.fromJson(e)).toList(),
      ),
    );
  }

  /// PATCH /admin/users/{id}/block أو /unblock
  Future<void> setUserBlocked(String id, {required bool blocked}) {
    final action = blocked ? 'block' : 'unblock';
    return _api.patch<void>('/admin/users/$id/$action');
  }

  /// PATCH /admin/users/{id}/role — ترقية/تخفيض صلاحية مستخدم
  Future<void> setUserRole(String id, String role) {
    return _api.patch<void>('/admin/users/$id/role', data: {'role': role});
  }
}
