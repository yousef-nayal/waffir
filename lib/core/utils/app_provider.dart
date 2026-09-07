import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waffir_app/models/models.dart';
import 'package:waffir_app/features/auth/data/auth_service.dart';
import 'package:waffir_app/core/network/api_exception.dart';
import 'package:waffir_app/core/network/services/product_service.dart';
import 'package:waffir_app/core/network/services/store_service.dart';
import 'package:waffir_app/core/network/services/price_service.dart';
import 'package:waffir_app/core/network/services/report_service.dart';
import 'package:waffir_app/core/network/services/catalog_service.dart';
import 'package:waffir_app/core/network/services/admin_user_service.dart';
import 'package:waffir_app/core/config/app_config.dart';
import 'package:waffir_app/core/constants/aleppo_blocks.dart';
import 'mock_data.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AppProvider extends ChangeNotifier {
  final AuthService _authService;

  AppProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _loadPreferences(); // ✅ تحميل التفضيلات عند البدء
  }

  // ── State ──────────────────────────────────────────────────────────────
  AuthStatus _authStatus = AuthStatus.initial;
  bool _isDarkMode = false;
  bool _isAdmin = false;
  // ✅ الموقع أصبح مكوّناً من قسمين منفصلين وصريحين: الكتلة الإدارية
  // (userBlock — إحدى الكتل الخمس الرسمية لمحافظة حلب) والمنطقة/الحي
  // (userLocation — يجب أن يكون ضمن أحياء الكتلة المختارة، راجع
  // aleppo_blocks.dart). سابقاً كان userLocation نصاً حراً بصيغة
  // "حلب - المنطقة" بلا أي ربط رسمي بالكتلة.
  String _userBlock = AleppoBlocks.all.first.name; // "الكتلة الأولى"
  String _userLocation = AleppoBlocks.all.first.areas.first; // "ألمجي"
  String _userName = '';
  String _userPhone = '';
  String _userId = '';
  String? _errorMessage;
  // ✅ جديد — نحتفظ بالمستخدم الكامل (يشمل pricesCount/ratingsCount/
  // reportsCount) بدل الاكتفاء بالاسم والهاتف فقط. هذا ما يحتاجه
  // ProfileScreen بدل الاعتماد على MockData.users.first كما كان سابقاً.
  UserModel? _currentUser;

  // ── Getters ──────────────────────────────────────────────────────────
  AuthStatus get authStatus => _authStatus;
  bool get isDarkMode => _isDarkMode;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _authStatus == AuthStatus.authenticated;
  bool get isLoading => _authStatus == AuthStatus.loading;

  /// اسم الكتلة الإدارية الحالية للمستخدم (مثال: "الكتلة الخامسة")
  String get userBlock => _userBlock;

  /// اسم المنطقة/الحي الحالي للمستخدم (مثال: "الفرقان")
  String get userLocation => _userLocation;

  /// نص عرض جاهز يجمع المنطقة والكتلة معاً: "الفرقان — الكتلة الخامسة"
  String get userLocationDisplay =>
      AleppoBlocks.displayLabel(block: _userBlock, area: _userLocation);
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get userId => _userId;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  // ══════════════════════════════════════════════════════════════════════
  // PREFERENCES PERSISTENCE
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _userBlock = prefs.getString('user_block') ?? AleppoBlocks.all.first.name;
    _userLocation =
        prefs.getString('user_area') ?? AleppoBlocks.all.first.areas.first;
    notifyListeners();
  }

  /// يُستدعى من SplashScreen للتحقق من وجود جلسة محفوظة (auto-login)
  Future<void> restoreSession() async {
    if (AppConfig.useMockData) return; // لا شيء لاستعادته في وضع العرض التجريبي
    final hasSession = await _authService.hasSavedSession();
    if (!hasSession) return;
    _setLoading();
    try {
      final user = await _authService.getCurrentUser();
      _setUser(user, isAdmin: user.role == 'admin');
    } catch (_) {
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // AUTH ACTIONS — النسخة الحقيقية (تُستخدم عندما AppConfig.useMockData = false)
  // ══════════════════════════════════════════════════════════════════════

  /// نقطة الدخول الوحيدة التي تستدعيها شاشات تسجيل الدخول.
  /// تتحول تلقائياً بين البيانات الوهمية والـ backend الحقيقي حسب
  /// [AppConfig.useMockData] — لا حاجة لتعديل أي شاشة عند ربط الـ backend.
  Future<bool> login({required String phone, required String password}) async {
    if (AppConfig.useMockData) {
      return loginMock(phone: phone);
    }
    _setLoading();
    try {
      final result = await _authService.login(phone: phone, password: password);
      _setUser(result.user, isAdmin: false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  /// ✅ سعر التسجيل: [block] و[area] يُرسلان معاً إلى الـ backend ضمن حقل
  /// sector كنص موحّد ("الكتلة الخامسة - الفرقان")، ويُحفظان محلياً بشكل
  /// منفصل فور نجاح العملية حتى تعرضهما الشاشات فوراً دون انتظار استجابة
  /// إضافية من الخادم.
  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String block,
    required String area,
  }) async {
    _userBlock = block;
    _userLocation = area;
    final sector = '$block - $area';
    if (AppConfig.useMockData) {
      return loginMock(name: name, phone: phone);
    }
    _setLoading();
    try {
      final result = await _authService.register(
        name: name,
        phone: phone,
        password: password,
        sector: sector,
      );
      // ✅ ملاحظة موثّقة في docs/API_ADDENDUM.md: التسجيل يعيد access/refresh
      // token فوراً حسب التوثيق، لكن المستخدم لا يزال بحاجة لتأكيد OTP قبل
      // اعتباره "مُفعَّلاً بالكامل". نحفظ بيانات المستخدم هنا حتى تكون شاشة
      // OTP قادرة على قراءتها، لكن الحالة العامة تبقى unauthenticated حتى
      // ينجح verifyOtp، فلا يُسمح للمستخدم بتخطي التفعيل عبر إعادة تشغيل
      // التطبيق مثلاً (راجع الملاحظة الكاملة في الملحق).
      _userName = result.user.name;
      _userPhone = result.user.phone;
      _userId = result.user.id;
      _currentUser = result.user;
      await _persistLocation();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  Future<bool> adminLogin({
    required String username,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      return loginMock(isAdmin: true, phone: username);
    }
    _setLoading();
    try {
      final result =
          await _authService.adminLogin(username: username, password: password);
      _setUser(result.user, isAdmin: true);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  Future<bool> forgotPassword(String phone) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }
    try {
      await _authService.forgotPassword(phone);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // ✅ دورة تفعيل الحساب (OTP) واستعادة كلمة المرور
  // (الـ 3 endpoints أدناه موثّقة الآن في docs/API_ADDENDUM.md)
  // ══════════════════════════════════════════════════════════════════════

  /// POST /auth/verify-otp — تأكيد رقم الهاتف بعد إنشاء حساب جديد
  Future<bool> verifyOtp({required String phone, required String code}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (code.length == 6) {
        _authStatus = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    }
    try {
      await _authService.verifyOtp(phone: phone, code: code);
      // ✅ الحساب الآن مُفعَّل فعلياً — نعتبر المستخدم مسجّل دخوله
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// POST /auth/resend-otp — إعادة إرسال رمز التحقق (تفعيل أو استعادة كلمة مرور)
  Future<bool> resendOtp({required String phone}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    try {
      await _authService.resendOtp(phone: phone);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// PUT /auth/reset-password — إتمام تعيين كلمة مرور جديدة بعد رمز التحقق
  Future<bool> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 700));
      return true;
    }
    try {
      await _authService.resetPassword(
        phone: phone,
        code: code,
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ✅ إصلاح جوهري: كانت هذه الدالة الوحيدة (مع changePassword أدناه) التي
  // تتجاهل AppConfig.useMockData وتستدعي _authService.updateProfile مباشرة
  // — أي طلب شبكة حقيقي دائماً، حتى في وضع العرض التجريبي. بما أنه لا يوجد
  // backend حقيقي متصل بعد، كان الطلب يفشل فوراً (ApiException من نوع
  // network/timeout)، وهذا هو السبب المباشر لظهور "تعذّر التحديث، حاول
  // مجدداً" عند تعديل الاسم من شاشة "الملف الشخصي". الآن تتبع نفس نمط بقية
  // دوال AppProvider (login, register, forgotPassword...): في وضع العرض
  // التجريبي تُحدَّث الحالة محلياً فوراً بلا أي اتصال شبكة.
  Future<bool> updateProfile({required String name}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      _userName = name;
      if (_currentUser != null)
        _currentUser = _currentUser!.copyWith(name: name);
      notifyListeners();
      return true;
    }
    try {
      await _authService.updateProfile(name: name);
      _userName = name;
      if (_currentUser != null)
        _currentUser = _currentUser!.copyWith(name: name);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ✅ نفس الإصلاح أعلاه: كانت تتجاهل AppConfig.useMockData أيضاً.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // MOCK LOGIN — تعمل فقط عندما AppConfig.useMockData = true
  // احذف استخدامها من شاشات auth_screens.dart عند تفعيل الـ backend الحقيقي
  // (استبدلها بـ provider.login / provider.register / provider.adminLogin)
  // ══════════════════════════════════════════════════════════════════════

  Future<bool> loginMock({
    bool isAdmin = false,
    String name = 'محمد أحمد',
    String phone = '0944123456',
  }) async {
    _setLoading();
    await Future.delayed(const Duration(milliseconds: 500));
    final mockUser = UserModel(
      id: isAdmin ? 'admin-1' : 'user-1',
      name: isAdmin ? 'مدير النظام' : name,
      phone: phone,
      role: isAdmin ? 'admin' : 'user',
      location: userLocationDisplay,
      pricesCount: isAdmin ? 0 : 45,
      ratingsCount: isAdmin ? 0 : 56,
      reportsCount: isAdmin ? 0 : 3,
    );
    _setUser(mockUser, isAdmin: isAdmin);
    return true;
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    _userName = '';
    _userPhone = '';
    _userId = '';
    _isAdmin = false;
    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Preferences ──────────────────────────────────────────────────────

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    // ✅ حفظ دائم
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
  }

  /// ✅ محدَّث — يستقبل الكتلة والمنطقة معاً. تُستخدم من: منتقي الموقع في
  /// الصفحة الرئيسية (showLocationPickerSheet)، وشاشة "تغيير الموقع" في
  /// الإعدادات. لا يزال بالإمكان تمرير [area] فقط عند التأكد أنها تنتمي إلى
  /// [block] الحالية (مثال نادر)، لكن الاستخدام الطبيعي دائماً يمرّر الاثنين.
  Future<void> updateLocation({
    required String block,
    required String area,
  }) async {
    _userBlock = block;
    _userLocation = area;
    notifyListeners();
    await _persistLocation();
  }

  Future<void> _persistLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_block', _userBlock);
    await prefs.setString('user_area', _userLocation);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Private Helpers ───────────────────────────────────────────────────

  void _setLoading() {
    _authStatus = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setUser(UserModel user, {required bool isAdmin}) {
    _userName = user.name;
    _userPhone = user.phone;
    _userId = user.id;
    // ✅ نحاول استخراج الكتلة والمنطقة من location القادم من الخادم بصيغة
    // "الكتلة الخامسة - الفرقان"؛ إن تعذّر ذلك (مستخدم قديم مثلاً) نُبقي على
    // آخر كتلة/منطقة محفوظة محلياً بدل استبدالها بقيمة فارغة.
    if (user.location.isNotEmpty && user.location.contains(' - ')) {
      final parts = user.location.split(' - ');
      if (parts.length >= 2) {
        _userBlock = parts[0].trim();
        _userLocation = parts.sublist(1).join(' - ').trim();
      }
    }
    _isAdmin = isAdmin;
    _currentUser = user;
    _authStatus = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
    _persistLocation();
  }

  void _setError(String message) {
    _authStatus = AuthStatus.unauthenticated;
    _errorMessage = message;
    notifyListeners();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// شِفرة مشتركة لكل الـ Providers أدناه
// ══════════════════════════════════════════════════════════════════════════
enum LoadingState { initial, loading, success, error }

// ══════════════════════════════════════════════════════════════════════════
// PRODUCT PROVIDER
// ══════════════════════════════════════════════════════════════════════════
class ProductProvider extends ChangeNotifier {
  final ProductService _service;
  ProductProvider({ProductService? service})
      : _service = service ?? ProductService();

  LoadingState _state = LoadingState.initial;
  List<ProductModel> _products = [];
  String? _errorMessage;
  bool _hasNextPage = false;
  int _currentPage = 1;
  String? _search;
  String? _category;

  LoadingState get state => _state;
  List<ProductModel> get products => _products;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LoadingState.loading;
  bool get hasNextPage => _hasNextPage;

  Future<void> loadProducts({
    String? category,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh || category != _category || search != _search) {
      _products = [];
      _currentPage = 1;
    }
    _category = category;
    _search = search;
    _state = LoadingState.loading;
    notifyListeners();

    // ── وضع العرض التجريبي: استخدم MockData مباشرة ──────────────────────
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _products = category == null || category == 'الكل'
          ? MockData.products
          : MockData.products.where((p) => p.category == category).toList();
      _hasNextPage = false;
      _state = LoadingState.success;
      notifyListeners();
      return;
    }

    // ── الوضع الحقيقي: يقرأ من الـ backend عبر ProductService ───────────
    try {
      final response = await _service.getProducts(
        search: search,
        category: category,
        page: _currentPage,
      );
      _products = [..._products, ...?response.data];
      _hasNextPage = response.pagination?.hasNextPage ?? false;
      _currentPage++;
      _state = LoadingState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = LoadingState.error;
    } finally {
      notifyListeners();
    }
  }

  /// ✅ جديد — تُستخدم من "إدارة المنتجات" في لوحة الإدارة
  Future<bool> createProduct({
    required String name,
    required String category,
    required String unit,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      _products = [
        ..._products,
        ProductModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          category: category,
          officialPrice: 0,
          realPrice: 0,
          avgPrice: 0,
          unit: unit,
          pricesCount: 0,
          changePercent: 0,
          isPriceUp: false,
        ),
      ];
      notifyListeners();
      return true;
    }
    try {
      final p = await _service.createProduct(
          name: name, category: category, unit: unit);
      _products = [..._products, p];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// ✅ جديد
  Future<bool> deleteProduct(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _products = _products.where((p) => p.id != id).toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.deleteProduct(id);
      _products = _products.where((p) => p.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// STORE PROVIDER
// ══════════════════════════════════════════════════════════════════════════
class StoreProvider extends ChangeNotifier {
  final StoreService _service;
  StoreProvider({StoreService? service}) : _service = service ?? StoreService();

  LoadingState _state = LoadingState.initial;
  List<StoreModel> _stores = [];
  String? _errorMessage;
  bool _hasNextPage = false;
  int _currentPage = 1;

  LoadingState get state => _state;
  List<StoreModel> get stores => _stores;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LoadingState.loading;
  bool get hasNextPage => _hasNextPage;

  Future<void> loadStores({
    String? sector,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _stores = [];
      _currentPage = 1;
    }
    _state = LoadingState.loading;
    notifyListeners();

    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _stores = MockData.stores.where((s) {
        final matchesSector =
            sector == null || sector == 'الكل' || s.sector == sector;
        final matchesSearch = search == null ||
            search.isEmpty ||
            s.name.contains(search) ||
            s.area.contains(search);
        return matchesSector && matchesSearch;
      }).toList();
      _hasNextPage = false;
      _state = LoadingState.success;
      notifyListeners();
      return;
    }

    try {
      final response = await _service.getStores(
        search: search,
        sector: sector,
        page: _currentPage,
      );
      _stores = [..._stores, ...?response.data];
      _hasNextPage = response.pagination?.hasNextPage ?? false;
      _currentPage++;
      _state = LoadingState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = LoadingState.error;
    } finally {
      notifyListeners();
    }
  }

  /// ✅ جديد — يُستخدم من ميزة "اقتراح متجر جديد" المتاحة للمستخدم العادي
  /// (POST /stores موثّقة أصلاً في API_DOCUMENTATION.md لهذا الغرض بالذات)
  Future<bool> createStore({
    required String name,
    required String address,
    required String area,
    required String sector,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      _stores = [
        ..._stores,
        StoreModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          address: address,
          area: area,
          sector: sector,
          isVerified: false,
        ),
      ];
      notifyListeners();
      return true;
    }
    try {
      final s = await _service.createStore(
          name: name, address: address, area: area, sector: sector);
      _stores = [..._stores, s];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// ✅ جديد — توثيق/إلغاء توثيق متجر (استخدام إداري)
  Future<bool> setVerified(String id, bool verified) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _stores = _stores
          .map((s) => s.id == id ? s.copyWith(isVerified: verified) : s)
          .toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.verifyStore(id, verified: verified);
      _stores = _stores
          .map((s) => s.id == id ? s.copyWith(isVerified: verified) : s)
          .toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// ✅ جديد
  Future<bool> deleteStore(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _stores = _stores.where((s) => s.id != id).toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.deleteStore(id);
      _stores = _stores.where((s) => s.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ جديد — PRICE PROVIDER
// يغطي: عرض أسعار منتج معيّن (ProductDetailScreen)، إرسال سعر جديد
// (AddPriceScreen)، التصويت (إعجاب/عدم إعجاب)، ومراجعة الإدارة
// (AdminPriceReviewScreen). كانت هذه كلها بلا أي Provider من قبل، والشاشات
// كانت تقرأ MockData.priceEntries مباشرة بغض النظر عن AppConfig.useMockData.
// ══════════════════════════════════════════════════════════════════════════
class PriceProvider extends ChangeNotifier {
  final PriceService _priceService;
  final ProductService _productService;
  PriceProvider({PriceService? priceService, ProductService? productService})
      : _priceService = priceService ?? PriceService(),
        _productService = productService ?? ProductService();

  LoadingState _state = LoadingState.initial;
  List<PriceEntry> _entries = [];
  String? _errorMessage;

  LoadingState get state => _state;
  List<PriceEntry> get entries => _entries;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LoadingState.loading;

  /// GET /products/{id}/prices — لعرض كل الأسعار المسجّلة لمنتج معيّن
  ///
  /// ✅ إصلاح جوهري (السبب المباشر لعدم ظهور "الأسعار المسجلة"):
  /// • كانت الدالة تتجاهل [productId] تماماً في وضع العرض التجريبي وتعيد
  ///   نفس القائمة الثابتة MockData.priceEntries لأي منتج، بغض النظر عن
  ///   المنتج المطلوب فعلياً — والآن تُفلتَر المدخلات حسب productId فعلياً.
  ///   راجع الإصلاح المقابل في mock_data.dart حيث أُضيف productId الحقيقي
  ///   لكل مدخلة، بالإضافة إلى مدخلتين جديدتين لمنتج "رز أبيض" الذي لم يكن
  ///   له أي سعر مسجّل من الأساس.
  /// • لم تكن القائمة القديمة _entries تُصفَّر عند بدء تحميل منتج جديد،
  ///   فكانت أسعار منتج سابق تبقى ظاهرة للحظة أو يختلط عرضها مع منتج آخر.
  /// • _requestToken يحمي من مشكلة الطلبات غير المرتّبة: إن انتقل
  ///   المستخدم بسرعة بين منتجين، لا تعود نتيجة الطلب الأقدم لتكتب فوق
  ///   نتيجة الطلب الأحدث بعد اكتمالها.
  /// • وضع العرض التجريبي أصبح أيضاً محاطاً بـ try/catch (كان بلا حماية
  ///   إطلاقاً) حتى لا تتجمّد الشاشة صامتة في حال حدوث أي خطأ غير متوقع.
  int _requestToken = 0;

  Future<void> loadProductPrices(String productId) async {
    final myToken = ++_requestToken;
    _state = LoadingState.loading;
    _errorMessage = null;
    _entries = []; // ✅ تصفير فوري لمنع ظهور أسعار منتج سابق أثناء التحميل
    notifyListeners();

    if (AppConfig.useMockData) {
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        if (myToken != _requestToken) return; // طلب أحدث تجاوز هذا الطلب
        _entries = MockData.priceEntries
            .where((e) => e.productId == productId)
            .toList();
        _state = LoadingState.success;
      } catch (_) {
        if (myToken != _requestToken) return;
        _errorMessage = 'حدث خطأ غير متوقع أثناء تحميل الأسعار';
        _state = LoadingState.error;
      } finally {
        if (myToken == _requestToken) notifyListeners();
      }
      return;
    }

    try {
      final result = await _productService.getProductPrices(productId);
      if (myToken != _requestToken) return;
      _entries = result;
      _state = LoadingState.success;
    } on ApiException catch (e) {
      if (myToken != _requestToken) return;
      _errorMessage = e.message;
      _state = LoadingState.error;
    } catch (e) {
      if (myToken != _requestToken) return;
      // ✅ يلتقط أي خطأ غير متوقع (parsing، null، إلخ) بدل تركه يعلّق
      // الحالة على "جارٍ التحميل" إلى الأبد بصمت.
      _errorMessage = 'حدث خطأ غير متوقع أثناء تحميل الأسعار';
      _state = LoadingState.error;
    } finally {
      if (myToken == _requestToken) notifyListeners();
    }
  }

  /// GET /prices — لمراجعة الإدارة
  Future<void> loadAdminPrices({String? status}) async {
    _state = LoadingState.loading;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _entries = status == null || status == 'الكل'
          ? MockData.priceEntries
          : MockData.priceEntries.where((e) => e.status == status).toList();
      _state = LoadingState.success;
      notifyListeners();
      return;
    }
    try {
      final response = await _priceService.getPrices(status: status);
      _entries = response.data ?? [];
      _state = LoadingState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = LoadingState.error;
    } finally {
      notifyListeners();
    }
  }

  /// POST /prices — من شاشة "إضافة سعر"
  Future<bool> submitPrice({
    required String productId,
    required String storeId,
    required double price,
    required String unit,
    required double quantity,
    String? brand,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    }
    try {
      await _priceService.submitPrice(
        productId: productId,
        storeId: storeId,
        price: price,
        unit: unit,
        quantity: quantity,
        brand: brand,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// POST /prices/{id}/vote — تحديث متفائل (optimistic) لعدّاد التقييمات
  Future<bool> vote(String id, {required bool isUp}) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    final previous = idx == -1 ? null : _entries[idx];
    if (idx != -1) {
      _entries[idx] = previous!.copyWith(
        thumbsUp: previous.thumbsUp + (isUp ? 1 : 0),
        thumbsDown: previous.thumbsDown + (isUp ? 0 : 1),
        totalRatings: previous.totalRatings + 1,
      );
      notifyListeners();
    }
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }
    try {
      await _priceService.votePrice(id, isUp: isUp);
      return true;
    } on ApiException catch (e) {
      // تراجع عن التحديث المتفائل عند الفشل
      if (idx != -1 && previous != null) {
        _entries[idx] = previous;
      }
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// PATCH /prices/{id}/approve أو /reject — مراجعة إدارية
  Future<bool> review(String id, {required bool approve}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      _entries = _entries.where((e) => e.id != id).toList();
      notifyListeners();
      return true;
    }
    try {
      await _priceService.reviewPrice(id, approve: approve);
      _entries = _entries.where((e) => e.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ جديد — REPORT PROVIDER
// كانت ReportService مكتوبة بالكامل وموثّقة لكن غير مستخدمة من أي شاشة —
// لا في شاشة المستخدم (لا يوجد زر بلاغ فعلي) ولا في لوحة الإدارة (كانت
// تعرض MockData.reports مباشرة).
// ══════════════════════════════════════════════════════════════════════════
class ReportProvider extends ChangeNotifier {
  final ReportService _service;
  ReportProvider({ReportService? service})
      : _service = service ?? ReportService();

  LoadingState _state = LoadingState.initial;
  List<ReportModel> _reports = [];
  String? _errorMessage;

  LoadingState get state => _state;
  List<ReportModel> get reports => _reports;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LoadingState.loading;

  Future<void> loadReports({String? status}) async {
    _state = LoadingState.loading;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _reports = status == null || status == 'الكل'
          ? MockData.reports
          : MockData.reports.where((r) => r.status == status).toList();
      _state = LoadingState.success;
      notifyListeners();
      return;
    }
    try {
      final response = await _service.getReports(status: status);
      _reports = response.data ?? [];
      _state = LoadingState.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = LoadingState.error;
    } finally {
      notifyListeners();
    }
  }

  /// POST /reports — من زر البلاغ (🚩) في بطاقة السعر
  Future<bool> submitReport({
    required String priceEntryId,
    required String type,
    String? note,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    try {
      await _service.submitReport(
          priceEntryId: priceEntryId, type: type, note: note);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// PATCH /reports/{id} — استخدام إداري
  Future<bool> updateStatus(String id, String status) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _reports = _reports
          .map((r) => r.id == id ? r.copyWith(status: status) : r)
          .toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.updateReportStatus(id, status);
      _reports = _reports
          .map((r) => r.id == id ? r.copyWith(status: status) : r)
          .toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ جديد — CATALOG PROVIDER
// يغطي كل "بيانات المرجع" الإدارية: الأسعار الرسمية، الوحدات، العلامات
// التجارية، المواقع، بالإضافة إلى إحصائيات لوحة التحكم والنشاط الأخير.
// كل هذه كانت تُقرأ من MockData مباشرة في admin_shell.dart وhome_screen.dart
// رغم أن CatalogService توفّرها بالكامل عبر الـ backend.
// ══════════════════════════════════════════════════════════════════════════
class CatalogProvider extends ChangeNotifier {
  final CatalogService _service;
  CatalogProvider({CatalogService? service})
      : _service = service ?? CatalogService();

  List<OfficialPrice> officialPrices = [];
  List<UnitModel> units = [];
  List<BrandModel> brands = [];
  List<LocationModel> locations = [];
  Map<String, dynamic> dashboardStats = {};
  List<Map<String, dynamic>> recentActivity = [];
  bool isLoading = false;
  String? errorMessage;
  // ✅ جديد — سجل تغييرات السعر الرسمي للمادة المفتوحة حالياً
  List<OfficialPriceHistoryEntry> officialPriceHistory = [];
  bool isLoadingHistory = false;
  String? historyErrorMessage;

  // ── الأسعار الرسمية ──────────────────────────────────────────────────
  Future<void> loadOfficialPrices({String? search}) async {
    isLoading = true;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      officialPrices = MockData.officialPrices;
      isLoading = false;
      notifyListeners();
      return;
    }
    try {
      officialPrices = await _service.getOfficialPrices(search: search);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addOfficialPrice({
    required String productName,
    required String unit,
    required double quantity,
    required double price,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      officialPrices = [
        ...officialPrices,
        OfficialPrice(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productName: productName,
          unit: unit,
          quantity: quantity,
          price: price,
          updatedAt: DateTime.now(),
        ),
      ];
      notifyListeners();
      return true;
    }
    try {
      final op = await _service.createOfficialPrice(
          productName: productName,
          unit: unit,
          quantity: quantity,
          price: price);
      officialPrices = [...officialPrices, op];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// GET /official-prices/{id}/history — ✅ جديد
  /// يُستدعى من OfficialPriceHistoryScreen عند فتح مادة معيّنة.
  Future<void> loadOfficialPriceHistory(String officialPriceId) async {
    isLoadingHistory = true;
    officialPriceHistory = [];
    historyErrorMessage = null;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      officialPriceHistory =
          MockData.officialPriceHistory[officialPriceId] ?? [];
      isLoadingHistory = false;
      notifyListeners();
      return;
    }
    try {
      officialPriceHistory =
          await _service.getOfficialPriceHistory(officialPriceId);
    } on ApiException catch (e) {
      historyErrorMessage = e.message;
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ── الوحدات ──────────────────────────────────────────────────────────
  Future<void> loadUnits() async {
    isLoading = true;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      units = MockData.units;
      isLoading = false;
      notifyListeners();
      return;
    }
    try {
      units = await _service.getUnits();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addUnit(String name) async {
    if (name.trim().isEmpty) return false;
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      units = [
        ...units,
        UnitModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            usageCount: 0)
      ];
      notifyListeners();
      return true;
    }
    try {
      final u = await _service.createUnit(name);
      units = [...units, u];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUnit(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      units = units.where((u) => u.id != id).toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.deleteUnit(id);
      units = units.where((u) => u.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── العلامات التجارية ────────────────────────────────────────────────
  Future<void> loadBrands() async {
    isLoading = true;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      brands = MockData.brands;
      isLoading = false;
      notifyListeners();
      return;
    }
    try {
      brands = await _service.getBrands();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBrand(String name) async {
    if (name.trim().isEmpty) return false;
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      brands = [
        ...brands,
        BrandModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            productsCount: 0)
      ];
      notifyListeners();
      return true;
    }
    try {
      final b = await _service.createBrand(name);
      brands = [...brands, b];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBrand(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      brands = brands.where((b) => b.id != id).toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.deleteBrand(id);
      brands = brands.where((b) => b.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── المواقع والقطاعات ────────────────────────────────────────────────
  Future<void> loadLocations({String? search}) async {
    isLoading = true;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      locations = MockData.locations;
      isLoading = false;
      notifyListeners();
      return;
    }
    try {
      locations = await _service.getLocations(search: search);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ محدَّث — [sector] هنا هو اسم الكتلة الإدارية (مثال: "الكتلة الخامسة")
  /// بدل نص محافظة حر كما كان سابقاً، تماشياً مع بقية التطبيق.
  Future<bool> addLocation({
    required String sector,
    required String area,
    required String landmark,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      locations = [
        ...locations,
        LocationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sector: sector,
            area: area,
            landmark: landmark,
            storesCount: 0)
      ];
      notifyListeners();
      return true;
    }
    try {
      final l = await _service.createLocation(
          sector: sector, area: area, landmark: landmark);
      locations = [...locations, l];
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── لوحة التحكم ──────────────────────────────────────────────────────
  Future<void> loadDashboardStats() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      dashboardStats = MockData.dashboardStats;
      notifyListeners();
      return;
    }
    try {
      dashboardStats = await _service.getDashboardStats();
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> loadRecentActivity() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      recentActivity = MockData.recentActivity;
      notifyListeners();
      return;
    }
    try {
      recentActivity = await _service.getRecentActivity();
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ جديد — ADMIN USERS PROVIDER
// كانت AdminUserService (حظر/رفع حظر/تغيير دور) مكتوبة بالكامل لكن غير
// مستخدمة من AdminUsersScreen التي كانت تعرض جدولاً بلا أي إجراء إطلاقاً.
// ══════════════════════════════════════════════════════════════════════════
class AdminUsersProvider extends ChangeNotifier {
  final AdminUserService _service;
  AdminUsersProvider({AdminUserService? service})
      : _service = service ?? AdminUserService();

  List<UserModel> users = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadUsers({String? search, String? status}) async {
    isLoading = true;
    notifyListeners();
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      users = MockData.users.where((u) {
        final matchesSearch = search == null ||
            search.isEmpty ||
            u.name.contains(search) ||
            u.phone.contains(search);
        return matchesSearch;
      }).toList();
      isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final response = await _service.getUsers(search: search, status: status);
      users = response.data ?? [];
    } on ApiException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setBlocked(String id, bool blocked) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      users = users
          .map((u) => u.id == id ? u.copyWith(isActive: !blocked) : u)
          .toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.setUserBlocked(id, blocked: blocked);
      users = users
          .map((u) => u.id == id ? u.copyWith(isActive: !blocked) : u)
          .toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setRole(String id, String role) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      users =
          users.map((u) => u.id == id ? u.copyWith(role: role) : u).toList();
      notifyListeners();
      return true;
    }
    try {
      await _service.setUserRole(id, role);
      users =
          users.map((u) => u.id == id ? u.copyWith(role: role) : u).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
