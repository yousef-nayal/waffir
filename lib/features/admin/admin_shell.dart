import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/mock_data.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/app_provider.dart';
import '../../core/constants/aleppo_blocks.dart';
import '../../models/models.dart';
import 'package:provider/provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN SHELL
// ✅ إصلاح جوهري شامل لهذا الملف: كانت كل شاشة إدارية (النظرة العامة،
// مراجعة الأسعار، البلاغات، المستخدمين، المنتجات، المتاجر، المواقع،
// الوحدات، العلامات، الأسعار الرسمية) تقرأ MockData.xxx مباشرة، رغم وجود
// خدمات كاملة وموثّقة (AdminUserService, ReportService, PriceService,
// CatalogService, ProductService, StoreService) لم تكن تُستدعى من أي مكان.
// تبديل AppConfig.useMockData إلى false لم يكن يغيّر شيئاً هنا سابقاً.
// الآن كل شاشة تمر عبر Provider مخصص (راجع core/utils/app_provider.dart)
// يتحول تلقائياً بين البيانات الوهمية والـ backend الحقيقي، بالإضافة إلى
// إجراءات فعلية (موافقة/رفض سعر، حظر مستخدم، توثيق متجر، حذف عنصر...) كانت
// كلها بلا استجابة سابقاً.
//
// ✅ جديد — أُضيف فلتر "الحي" (المنطقة) بجانب فلتر "الكتلة الإدارية"
// الموجود مسبقاً في: إدارة المتاجر، مراجعة الأسعار، إدارة البلاغات،
// وإدارة المواقع. صف فلاتر الأحياء يظهر فقط بعد اختيار كتلة محددة (بنفس
// نمط stores_screen.dart)، ويُعاد ضبطه تلقائياً إلى "الكل" عند تغيير
// الكتلة لمنع بقاء حي لا ينتمي إليها.
//
// ✅ إصلاح شكل الأزرار: زر "حسناً" في نافذة "معلومات الحساب" (وأي حوار
// مشابه) كان ElevatedButton بلا تغليف SizedBox عريض ومع minimumSize(0, 40)
// — القيمة 0 للعرض تجعله ينكمش على حجم النص فقط فيبدو كحبّة ضيقة غير
// احترافية. تم إصلاحه أدناه في _showAccountInfo (راجع نفس الإصلاح في
// profile_screen.dart لشاشتَي "المساعدة والدعم" و"عن التطبيق").
//
// ✅ جديد — أُعيد زر تبديل الثيم (فاتح/داكن) إلى شريط العنوان العلوي
// (AppBar) المشترك في AdminShell، ليظهر في كل شاشات لوحة الإدارة (النظرة
// العامة، مراجعة الأسعار، البلاغات، المستخدمين، المنتجات، المتاجر،
// المواقع، الوحدات، العلامات، الأسعار الرسمية، التحليلات) ما عدا شاشة
// "الإعدادات" (AdminSettingsScreen) تحديداً، لأنها تحتوي أصلاً على عنصر
// تحكم مخصص لنفس الغرض (مفتاح Switch ضمن بطاقة "الوضع الليلي"، راجع
// AdminSettingsScreen._buildBody أدناه)، فلا داعي لتكراره في الأعلى هناك.
//
// ✅ إصلاح جوهري إضافي (بلا أي تغيير في باقي الشاشات): نافذة "إضافة سعر
// رسمي جديد" ضمن AdminOfficialPricesScreen كانت تستقبل اسم منتج ووحدة
// كنصين حرّين (TextField) لا يملكان أي ربط فعلي بجدولي Product/Unit في
// قاعدة البيانات (مخطط قاعدة البيانات الفعلي لجدول OfficialPrice لا يحتوي
// أي عمود نصي لاسم المنتج أو الوحدة، فقط product_id/unit_id). استُبدل ذلك
// بقائمتين منسدلتين تختاران منتجاً/وحدة موجودَين فعلاً، بنفس نمط النافذة
// المطابق تماماً (نفس العنوان، الحقول، الأزرار)، راجع
// AdminOfficialPricesScreen._showAddOfficialPrice أدناه للتفاصيل الكاملة.
// ══════════════════════════════════════════════════════════════════════════════
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const double _wideBreakpoint = 900;

  bool _sidebarOpen = false; // يُستخدم فقط في وضع الشاشة العريضة
  int _selectedIndex = 0;

  final _labels = [
    'نظرة عامة',
    'مراجعة الأسعار',
    'إدارة البلاغات',
    'إدارة المستخدمين',
    'إدارة المنتجات',
    'إدارة المتاجر',
    'إدارة المواقع',
    'إدارة الواحدات',
    'إدارة العلامات',
    'الأسعار الرسمية',
    'التحليلات',
    'الإعدادات',
  ];

  final _icons = [
    Icons.dashboard_outlined,
    Icons.attach_money,
    Icons.flag_outlined,
    Icons.people_outlined,
    Icons.inventory_2_outlined,
    Icons.store_outlined,
    Icons.location_on_outlined,
    Icons.tag,
    Icons.label_outlined,
    Icons.description_outlined,
    Icons.bar_chart,
    Icons.settings_outlined,
  ];

  // ✅ فهرس شاشة "الإعدادات" ضمن _labels/_icons — يُستخدم لإخفاء زر تبديل
  // الثيم في شريط العنوان العلوي عندما تكون هذه الشاشة هي المعروضة حالياً،
  // بما أنها تحتوي أصلاً عنصر تحكم مخصص لنفس الغرض.
  static const int _settingsIndex = 11;

  Widget get _currentScreen {
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboard();
      case 1:
        return const AdminPriceReviewScreen();
      case 2:
        return const AdminReportsScreen();
      case 3:
        return const AdminUsersScreen();
      case 4:
        return const AdminProductsScreen();
      case 5:
        return const AdminStoresScreen();
      case 6:
        return const AdminLocationsScreen();
      case 7:
        return const AdminUnitsScreen();
      case 8:
        return const AdminBrandsScreen();
      case 9:
        return const AdminOfficialPricesScreen();
      case 10:
        return const AdminAnalyticsScreen();
      case 11:
        return const AdminSettingsScreen();
      default:
        return const AdminDashboard();
    }
  }

  Widget _sidebarList(bool closeAsDrawer) => Container(
        color: AppColors.surfaceOf(context),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: List.generate(
              _labels.length,
              (i) => SidebarItem(
                icon: _icons[i],
                label: _labels[i],
                isSelected: _selectedIndex == i,
                onTap: () {
                  setState(() {
                    _selectedIndex = i;
                    _sidebarOpen = false;
                  });
                  if (closeAsDrawer) Navigator.pop(context); // يُغلق الـ Drawer
                },
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _wideBreakpoint;
    // ✅ جديد — نحتاج AppProvider هنا لعرض وتبديل حالة الوضع الداكن عبر
    // الزر المُعاد في شريط العنوان العلوي.
    final appProvider = context.watch<AppProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('وفّر - لوحة الإدارة'),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => isWide
                  ? setState(() => _sidebarOpen = !_sidebarOpen)
                  : Scaffold.of(ctx).openDrawer(),
            ),
          ),
          // ══════════════════════════════════════════════════════════════
          // ✅ جديد — زر تبديل الثيم (فاتح/داكن) في شريط العنوان العلوي،
          // يظهر في كل شاشات لوحة الإدارة ما عدا شاشة "الإعدادات" (فهرسها
          // _settingsIndex) لأنها تحتوي على عنصر تحكم مخصص لنفس الغرض
          // (Switch ضمن بطاقة "الوضع الليلي").
          // ══════════════════════════════════════════════════════════════
          actions: _selectedIndex == _settingsIndex
              ? null
              : [
                  IconButton(
                    icon: Icon(
                      appProvider.isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    tooltip: appProvider.isDarkMode
                        ? 'الوضع الفاتح'
                        : 'الوضع الداكن',
                    onPressed: appProvider.toggleDarkMode,
                  ),
                  const SizedBox(width: 4),
                ],
        ),
        drawer: isWide ? null : Drawer(child: _sidebarList(true)),
        body: isWide
            ? Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _sidebarOpen ? 220 : 0,
                    child: _sidebarOpen ? _sidebarList(false) : null,
                  ),
                  if (_sidebarOpen) const VerticalDivider(width: 1),
                  Expanded(child: _currentScreen),
                ],
              )
            : _currentScreen,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// رأس متدرّج مشترك
// ══════════════════════════════════════════════════════════════════════════════
class _AdminGradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _AdminGradientHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        actionIcon ?? Icons.add,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ✅ الآن يقرأ من CatalogProvider.dashboardStats/recentActivity بدل
// MockData مباشرة.
// ══════════════════════════════════════════════════════════════════════════════
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadDashboardStats();
      catalog.loadRecentActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final stats = catalog.dashboardStats.isEmpty
        ? MockData.dashboardStats
        : catalog.dashboardStats;
    final activity = catalog.recentActivity.isEmpty
        ? MockData.recentActivity
        : catalog.recentActivity;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _AdminGradientHeader(
          title: 'نظرة عامة',
          subtitle: 'ملخص إحصائيات النظام',
          icon: Icons.dashboard_outlined,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              StatCard(
                icon: Icons.people_outlined,
                iconColor: Colors.blue,
                iconBg: Colors.blue.withValues(alpha: 0.1),
                value: '${stats['totalUsers']}',
                label: 'إجمالي المستخدمين',
                growth: '${stats['usersGrowth']}%+',
                isPositive: true,
              ),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.green,
                iconBg: Colors.green.withValues(alpha: 0.1),
                value: '${stats['totalProducts']}',
                label: 'إجمالي المنتجات',
                growth: '${stats['productsGrowth']}%+',
                isPositive: true,
              ),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.store_outlined,
                iconColor: Colors.purple,
                iconBg: Colors.purple.withValues(alpha: 0.1),
                value: '${stats['totalStores']}',
                label: 'إجمالي المتاجر',
                growth: '${stats['storesGrowth']}%+',
                isPositive: true,
              ),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.attach_money,
                iconColor: Colors.orange,
                iconBg: Colors.orange.withValues(alpha: 0.1),
                value: '${stats['totalPrices']}',
                label: 'إجمالي الأسعار',
                growth: '${stats['pricesGrowth']}%+',
                isPositive: true,
              ),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.flag_outlined,
                iconColor: Colors.red,
                iconBg: Colors.red.withValues(alpha: 0.1),
                value: '${stats['totalReports']}',
                label: 'إجمالي البلاغات',
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'النشاط الأخير',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Column(
                  children: activity.map((a) {
                    final colorMap = {
                      'blue': AppColors.primary,
                      'red': AppColors.error,
                      'green': AppColors.success,
                      'purple': Colors.purple,
                    };
                    final color = colorMap[a['color']] ?? AppColors.primary;
                    return ListTile(
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        a['text'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimaryOf(context),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      subtitle: Text(
                        a['time'],
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 11,
                        ),
                      ),
                      subtitleTextStyle: const TextStyle(),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PRICE REVIEW SCREEN
// ✅ الآن يقرأ من PriceProvider.loadAdminPrices() وتوجد أزرار موافقة/رفض
// فعلية تستدعي PriceProvider.deletePrice() (كانت الشاشة سابقاً جدولاً للعرض فقط
// بلا أي إجراء).
// ✅ جديد — فلتر الحي بجانب فلتر الكتلة الإدارية، يظهر فقط بعد اختيار كتلة.
// ══════════════════════════════════════════════════════════════════════════════
class AdminPriceReviewScreen extends StatefulWidget {
  const AdminPriceReviewScreen({super.key});
  @override
  State<AdminPriceReviewScreen> createState() => _AdminPriceReviewScreenState();
}

class _AdminPriceReviewScreenState extends State<AdminPriceReviewScreen> {
  // ══════════════════════════════════════════════════════════════════════
  // ✅ إصلاح جوهري — أُزيل فلتر "قيد المراجعة" (كان يعتمد على e.status)
  // لأن جدول Price في قاعدة البيانات الفعلية (Waffir_Database.txt) لا
  // يحتوي عمود status إطلاقاً. أُبقي فلتر "مشهورة" فقط لأنه فرز عرضي بحت
  // (حسب totalRatings) لا يعتمد على أي عمود غير موجود.
  // ══════════════════════════════════════════════════════════════════════
  String _filter = 'الكل';
  // ✅ فلتر الكتلة الإدارية، يُشتق تصنيف كل سعر تلقائياً من حقل
  // e.storeArea الموجود أصلاً في PriceEntry عبر AleppoBlocks.blockOfArea
  // (بلا حاجة لتعديل الـ model أو الـ backend).
  String _blockFilter = 'الكل';
  // ✅ جديد — فلتر الحي، يظهر فقط بعد اختيار كتلة إدارية محددة، ويُعاد
  // ضبطه تلقائياً إلى "الكل" كلما تغيّرت الكتلة.
  String _areaFilter = 'الكل';
  // ✅ جديد — نص البحث، يُطبَّق محلياً على اسم المنتج/المتجر/المستخدم
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PriceProvider>().loadAdminPrices();
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // ✅ إصلاح جوهري — حلّت محل _review(approve/reject). جدول Price لا
  // يحتوي عمود status، ومخطط حالات الاستخدام يُدرج "حذف السعر" صراحة
  // كالإجراء الإداري الوحيد ضمن "مراجعة الأسعار". يُطلب تأكيد صريح قبل
  // الحذف بما أنه إجراء نهائي لا رجعة فيه.
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _deletePrice(PriceEntry e) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف السعر',
      message: 'هل تريد حذف سعر "${e.productName}" نهائياً؟',
      confirmText: 'حذف',
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<PriceProvider>().deletePrice(e.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حذف السعر' : 'تعذّر حذف السعر'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceProvider = context.watch<PriceProvider>();
    var entries = priceProvider.entries;
    if (_search.trim().isNotEmpty) {
      final q = _search.trim();
      entries = entries
          .where((e) =>
              e.productName.contains(q) ||
              e.storeName.contains(q) ||
              e.submittedBy.contains(q))
          .toList();
    }
    if (_blockFilter != 'الكل') {
      entries = entries
          .where(
            (e) => AleppoBlocks.blockOfArea(e.storeArea)?.name == _blockFilter,
          )
          .toList();
    }
    // ✅ جديد — فلترة إضافية حسب الحي المحدد
    if (_areaFilter != 'الكل') {
      entries = entries.where((e) => e.storeArea == _areaFilter).toList();
    }
    // ✅ "مشهورة" فرز عرضي حسب عدد التقييمات (لا يعتمد على عمود status)
    if (_filter == 'مشهورة') {
      entries = [...entries]
        ..sort((a, b) => b.totalRatings.compareTo(a.totalRatings));
    }

    return Column(
      children: [
        const _AdminGradientHeader(
          title: 'مراجعة الأسعار',
          subtitle: 'راجع الأسعار المقدمة من المستخدمين واحذف غير الصحيح منها',
          icon: Icons.attach_money,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ إصلاح — كان حقل البحث زخرفياً بلا onChanged؛ أصبح الآن
              // مربوطاً فعلياً بفلترة القائمة محلياً.
              WaffirSearchField(
                hint: 'ابحث عن منتج، متجر أو مستخدم...',
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              // فلتر الكتلة الإدارية
              FilterChipRow(
                options: ['الكل', ...AleppoBlocks.blockNames],
                selected: _blockFilter,
                onSelected: (v) => setState(() {
                  _blockFilter = v;
                  // ✅ إعادة ضبط فلتر الحي تلقائياً عند تغيير الكتلة
                  _areaFilter = 'الكل';
                }),
              ),
              // ✅ جديد — صف فلترة الحي (يظهر فقط بعد اختيار كتلة محددة)
              if (_blockFilter != 'الكل') ...[
                const SizedBox(height: 8),
                FilterChipRow(
                  options: [
                    'الكل',
                    ...AleppoBlocks.areasOfBlock(_blockFilter),
                  ],
                  selected: _areaFilter,
                  onSelected: (v) => setState(() => _areaFilter = v),
                ),
              ],
              const SizedBox(height: 8),
              FilterChipRow(
                options: const ['الكل', 'مشهورة'],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: priceProvider.isLoading && entries.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد أسعار مطابقة',
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) {
                        final e = entries[i];
                        final block =
                            AleppoBlocks.blockOfArea(e.storeArea)?.name;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.borderOf(context)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${e.price.toStringAsFixed(0)} ل.س',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.productName,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${e.quantity.toStringAsFixed(0)} ${e.unit}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${e.storeName} — بواسطة ${e.submittedBy}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                              if (block != null) ...[
                                const SizedBox(height: 6),
                                // ✅ شارة الكتلة الإدارية + الحي لكل سعر
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      e.storeArea.isEmpty
                                          ? block
                                          : '$block — ${e.storeArea}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              // ✅ إصلاح جوهري — زر "حذف السعر" فقط، بدل
                              // موافقة/رفض السابقين اللذين افترضا عمود status
                              // غير موجود فعلياً في جدول Price.
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _deletePrice(e),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  label: const Text(
                                    'حذف السعر',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                    minimumSize: const Size(0, 38),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REPORTS SCREEN
// ✅ الآن يقرأ من ReportProvider، وكل بلاغ يحمل زر "حذف" فعلي عبر
// ReportProvider.deleteReport() — حلّت محل تحديث الحالة (تمت المراجعة/تم
// الحل/قيد الانتظار) لأن جدول Report في قاعدة البيانات الفعلية لا يحتوي
// عمود status إطلاقاً، ومخطط حالات الاستخدام يُدرج "حذف البلاغ" صراحة
// كالإجراء الإداري الوحيد ضمن "إدارة البلاغات".
// ✅ أنواع البلاغات أصبحت مطابقة تماماً للقيم الثلاث الحصرية في عمود
// Report.type (راجع ReportType في models.dart): سعر مبالغ فيه، سعر غير
// صحيح، معلومات غير صحيحة — بدل 4 مفاتيح إنجليزية لم تكن تطابق القاعدة.
// ✅ جديد — فلتر الحي بجانب فلتر الكتلة الإدارية، يظهر فقط بعد اختيار كتلة.
// ══════════════════════════════════════════════════════════════════════════════
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  // ✅ فلتر حسب نوع البلاغ (القيم الثلاث الفعلية) بدل فلتر حالة غير موجودة
  String _filter = 'الكل';
  // ✅ فلتر الكتلة الإدارية، يُشتق تصنيف كل بلاغ تلقائياً من حقل
  // r.storeArea (راجع ReportModel في models.dart) عبر AleppoBlocks.blockOfArea.
  String _blockFilter = 'الكل';
  // ✅ جديد — فلتر الحي، يظهر فقط بعد اختيار كتلة إدارية محددة، ويُعاد
  // ضبطه تلقائياً إلى "الكل" كلما تغيّرت الكتلة.
  String _areaFilter = 'الكل';
  // ✅ جديد — نص البحث المربوط فعلياً بحقل البحث
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  String _typeLabel(String t) {
    switch (t) {
      case ReportType.overpriced:
        return 'سعر\nمبالغ فيه';
      case ReportType.wrongPrice:
        return 'سعر\nغير صحيح';
      case ReportType.wrongInfo:
        return 'معلومات\nغير صحيحة';
      default:
        return t;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case ReportType.overpriced:
        return AppColors.warning;
      case ReportType.wrongPrice:
        return AppColors.error;
      case ReportType.wrongInfo:
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _deleteReport(ReportModel r) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف البلاغ',
      message: 'هل تريد حذف هذا البلاغ عن "${r.productName}" نهائياً؟',
      confirmText: 'حذف',
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<ReportProvider>().deleteReport(r.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حذف البلاغ' : 'تعذّر حذف البلاغ'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    var reports = _filter == 'الكل'
        ? reportProvider.reports
        : reportProvider.reports.where((r) => r.type == _filter).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.trim();
      reports = reports
          .where((r) =>
              r.productName.contains(q) ||
              r.storeName.contains(q) ||
              r.userName.contains(q))
          .toList();
    }
    if (_blockFilter != 'الكل') {
      reports = reports
          .where(
            (r) => AleppoBlocks.blockOfArea(r.storeArea)?.name == _blockFilter,
          )
          .toList();
    }
    // ✅ جديد — فلترة إضافية حسب الحي المحدد
    if (_areaFilter != 'الكل') {
      reports = reports.where((r) => r.storeArea == _areaFilter).toList();
    }

    return Column(
      children: [
        const _AdminGradientHeader(
          title: 'إدارة البلاغات',
          subtitle: 'راجع البلاغات المقدمة من المستخدمين واحذف غير اللازم منها',
          icon: Icons.flag_outlined,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ إصلاح — كان حقل البحث زخرفياً بلا onChanged
              WaffirSearchField(
                hint: 'ابحث عن منتج، متجر أو مستخدم...',
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              // فلتر الكتلة الإدارية
              FilterChipRow(
                options: ['الكل', ...AleppoBlocks.blockNames],
                selected: _blockFilter,
                onSelected: (v) => setState(() {
                  _blockFilter = v;
                  // ✅ إعادة ضبط فلتر الحي تلقائياً عند تغيير الكتلة
                  _areaFilter = 'الكل';
                }),
              ),
              // ✅ جديد — صف فلترة الحي (يظهر فقط بعد اختيار كتلة محددة)
              if (_blockFilter != 'الكل') ...[
                const SizedBox(height: 8),
                FilterChipRow(
                  options: [
                    'الكل',
                    ...AleppoBlocks.areasOfBlock(_blockFilter),
                  ],
                  selected: _areaFilter,
                  onSelected: (v) => setState(() => _areaFilter = v),
                ),
              ],
              const SizedBox(height: 8),
              FilterChipRow(
                options: const ['الكل', ...ReportType.all],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: reportProvider.isLoading && reports.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : reports.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد بلاغات مطابقة',
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: reports.length,
                      itemBuilder: (ctx, i) {
                        final r = reports[i];
                        final block =
                            AleppoBlocks.blockOfArea(r.storeArea)?.name;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _typeColor(
                                        r.type,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _typeLabel(r.type),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _typeColor(r.type),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r.productName} — ${r.storeName}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'بلّغ عنه: ${r.userName}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondaryOf(
                                              context,
                                            ),
                                          ),
                                        ),
                                        if (r.description != null &&
                                            r.description!.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              r.description!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color:
                                                    AppColors.textSecondaryOf(
                                                        context),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // ✅ زر الحذف الفعلي بدل تغيير الحالة
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.error, size: 20),
                                    onPressed: () => _deleteReport(r),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              if (block != null) ...[
                                const SizedBox(height: 6),
                                // ✅ شارة الكتلة الإدارية + الحي لكل بلاغ
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r.storeArea.isEmpty
                                          ? block
                                          : '$block — ${r.storeArea}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// USERS SCREEN
// ✅ الآن يقرأ من AdminUsersProvider، وكل صف قابل للنقر لفتح إجراءات فعلية:
// حظر/رفع حظر، ترقية/تخفيض دور، تعديل الاسم، وحذف نهائي — بالإضافة إلى زر
// "إضافة مستخدم" في الرأس. هذا يكمل الأفعال الخمسة الموحّدة (عرض/إضافة/
// تعديل/بحث/حذف) التي يُدرجها مخطط حالات الاستخدام لـ"إدارة المستخدمين"،
// وكانت "إضافة" و"حذف" و"تعديل" مفقودة تماماً سابقاً.
// ══════════════════════════════════════════════════════════════════════════════
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUsersProvider>().loadUsers();
      final catalog = context.read<CatalogProvider>();
      if (catalog.locations.isEmpty) catalog.loadLocations();
    });
  }

  Future<void> _openActions(UserModel u) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('تعديل الاسم'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: Icon(
                  u.isActive ? Icons.block : Icons.check_circle_outline,
                  color: u.isActive ? AppColors.error : AppColors.success,
                ),
                title: Text(u.isActive ? 'حظر المستخدم' : 'رفع الحظر'),
                onTap: () => Navigator.pop(ctx, 'toggle_block'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  u.role == 'admin' ? 'تخفيض إلى مستخدم' : 'ترقية إلى مدير',
                ),
                onTap: () => Navigator.pop(ctx, 'toggle_role'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('حذف المستخدم',
                    style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    final provider = context.read<AdminUsersProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (action == 'edit') {
      await _showEditUser(u);
      return;
    }
    if (action == 'delete') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'حذف المستخدم',
        message:
            'هل تريد حذف "${u.name}" نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
        confirmText: 'حذف',
        icon: Icons.delete_outline,
      );
      if (confirmed != true || !mounted) return;
      final ok = await provider.deleteUser(u.id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(ok ? 'تم حذف المستخدم' : 'تعذّر حذف المستخدم'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
      return;
    }

    bool ok = false;
    if (action == 'toggle_block') {
      ok = await provider.setBlocked(u.id, u.isActive);
    } else if (action == 'toggle_role') {
      ok = await provider.setRole(u.id, u.role == 'admin' ? 'user' : 'admin');
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم تنفيذ الإجراء' : 'تعذّر تنفيذ الإجراء'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _showEditUser(UserModel u) async {
    final nameCtrl = TextEditingController(text: u.name);
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل بيانات المستخدم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الاسم الكامل', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(hintText: 'اسم المستخدم'),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final navigator = Navigator.of(ctx);
                      final ok = await context
                          .read<AdminUsersProvider>()
                          .updateUser(u.id, name: nameCtrl.text.trim());
                      navigator.pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(ok ? 'تم تحديث البيانات' : 'تعذّر التحديث'),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.error,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero),
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    );
  }

  /// ✅ جديد — إضافة مستخدم جديد مباشرة من لوحة الإدارة، مطابقةً لعنصر
  /// "إضافة" الناقص سابقاً. يستخدم نفس منتقي الموقع الموحّد (الكتل الخمس)
  /// المستخدم في بقية التطبيق، ثم يترجم الاختيار إلى location_id حقيقي.
  void _showAddUser(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? selectedBlock;
    String? selectedArea;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إضافة مستخدم جديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الاسم الكامل', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: nameCtrl,
                      textDirection: TextDirection.rtl,
                      decoration:
                          const InputDecoration(hintText: 'مثال: أحمد محمد')),
                  const SizedBox(height: 14),
                  const Text('رقم الهاتف', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration:
                          const InputDecoration(hintText: '09xxxxxxxx')),
                  const SizedBox(height: 14),
                  const Text('كلمة المرور المبدئية',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(hintText: '6 أحرف على الأقل')),
                  const SizedBox(height: 14),
                  const Text('الكتلة والمنطقة', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showLocationPickerSheet(
                      context,
                      currentBlock: selectedBlock ?? '',
                      currentArea: selectedArea ?? '',
                      onSelect: (block, area) => setDialogState(() {
                        selectedBlock = block;
                        selectedArea = area;
                      }),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderOf(ctx)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedArea == null
                            ? 'اختر الكتلة الإدارية والمنطقة'
                            : AleppoBlocks.displayLabel(
                                block: selectedBlock!, area: selectedArea!),
                        style: TextStyle(
                            color: selectedArea == null
                                ? AppColors.textHintOf(ctx)
                                : AppColors.textPrimaryOf(ctx)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            passwordCtrl.text.trim().length < 6 ||
                            selectedArea == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى تعبئة كل الحقول بشكل صحيح'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        final locationId = context
                            .read<CatalogProvider>()
                            .locationIdForArea(selectedArea!);
                        final navigator = Navigator.of(ctx);
                        final ok =
                            await context.read<AdminUsersProvider>().createUser(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  password: passwordCtrl.text,
                                  locationId: locationId ?? '',
                                );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              ok ? 'تمت إضافة المستخدم' : 'تعذّرت الإضافة'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('إضافة'),
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<AdminUsersProvider>();
    final users = _filter == 'نشط'
        ? usersProvider.users.where((u) => u.isActive).toList()
        : _filter == 'محظور'
            ? usersProvider.users.where((u) => !u.isActive).toList()
            : usersProvider.users;

    return Column(
      children: [
        _AdminGradientHeader(
          title: 'إدارة المستخدمين',
          subtitle: 'إدارة حسابات المستخدمين والصلاحيات',
          icon: Icons.people_outlined,
          actionLabel: 'إضافة مستخدم',
          onAction: () => _showAddUser(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaffirSearchField(
                hint: 'ابحث عن اسم أو رقم هاتف...',
                onChanged: (v) =>
                    context.read<AdminUsersProvider>().loadUsers(search: v),
              ),
              const SizedBox(height: 10),
              FilterChipRow(
                options: const ['الكل', 'نشط', 'محظور'],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: usersProvider.isLoading && users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد مستخدمون',
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (ctx, i) {
                        final u = users[i];
                        return GestureDetector(
                          onTap: () => _openActions(u),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceOf(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.borderOf(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  u.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(u.phone,
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: u.role == 'admin'
                                        ? Colors.purple.withValues(alpha: 0.1)
                                        : AppColors.primary
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.role == 'admin' ? 'مدير' : 'مستخدم',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: u.role == 'admin'
                                          ? Colors.purple
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${u.pricesCount} سعر',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (!u.isActive)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.block,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PRODUCTS SCREEN
// ✅ الآن يقرأ من ProductProvider، وحوار "إضافة منتج" يستدعي فعلياً
// ProductProvider.createProduct (أُضيف حقل الوحدة الناقص)، وزر "⋮" يحذف
// المنتج فعلياً عبر ProductProvider.deleteProduct بعد تأكيد.
// ══════════════════════════════════════════════════════════════════════════════
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  /// ✅ جديد — نافذة إضافة/تعديل موحّدة. عند تمرير [existing] تعمل كنافذة
  /// تعديل (تُعبَّأ الحقول مسبقاً وتستدعي ProductProvider.updateProduct)،
  /// وإلا فهي نافذة إضافة كما كانت (ProductProvider.createProduct). هذا
  /// يكمل عنصر "تعديل" الناقص سابقاً في مخطط حالات الاستخدام.
  void _showProductDialog(BuildContext context, {ProductModel? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    String unit = existing?.unit ?? 'كغ';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اسم المنتج', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'مثال: زيت زيتون',
                  ),
                ),
                const SizedBox(height: 14),
                const Text('الفئة', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(hintText: 'مثال: زيوت'),
                ),
                const SizedBox(height: 14),
                const Text('الوحدة', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: unit,
                  items: const ['كغ', 'غرام', 'لتر', 'قطعة', 'علبة']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => unit = v ?? unit),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final navigator = Navigator.of(ctx);
                        final provider = context.read<ProductProvider>();
                        final ok = isEdit
                            ? await provider.updateProduct(
                                existing.id,
                                name: nameCtrl.text.trim(),
                                category: catCtrl.text.trim(),
                                unit: unit,
                              )
                            : await provider.createProduct(
                                name: nameCtrl.text.trim(),
                                category: catCtrl.text.trim(),
                                unit: unit,
                              );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? (isEdit
                                      ? 'تم تعديل المنتج'
                                      : 'تمت إضافة المنتج')
                                  : (isEdit
                                      ? 'تعذّر التعديل'
                                      : 'تعذّر إضافة المنتج'),
                            ),
                            backgroundColor:
                                ok ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(isEdit ? 'حفظ' : 'إضافة'),
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ProductModel p) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف المنتج',
      message: 'هل تريد حذف "${p.name}"؟',
      confirmText: 'حذف',
      icon: Icons.delete_outline,
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await context.read<ProductProvider>().deleteProduct(p.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(deleted ? 'تم حذف المنتج' : 'تعذّر الحذف'),
        backgroundColor: deleted ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    return Column(
      children: [
        _AdminGradientHeader(
          title: 'إدارة المنتجات',
          subtitle: 'أضف وراجع منتجات النظام',
          icon: Icons.inventory_2_outlined,
          actionLabel: 'إضافة منتج',
          onAction: () => _showProductDialog(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WaffirSearchField(
            hint: 'ابحث عن منتج أو فئة...',
            onChanged: (v) =>
                context.read<ProductProvider>().loadProducts(search: v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: productProvider.isLoading && productProvider.products.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: productProvider.products.length,
                  itemBuilder: (ctx, i) {
                    final p = productProvider.products[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      // ══════════════════════════════════════════════════
                      // ✅ إصلاح فيضان النص (overflow) — كانت البطاقة صفاً
                      // واحداً: اسم المنتج كنص غير مرن بلا حد أقصى للأسطر
                      // يليه Spacer، فحين يطول اسم المنتج (مثال: "زيت زيتون
                      // فلسطين") يتجاوز الصف عرض الشاشة المتاح فعلياً
                      // ("RIGHT OVERFLOWED" في وضع التصحيح). الحل: اسم
                      // المنتج أصبح داخل Expanded بسطر واحد وعلامة "..."
                      // عند الحاجة، وانتقلت بيانات الفئة/عدد الأسعار/متوسط
                      // السعر إلى صف ثانٍ منفصل، بلا أي تغيير في المعلومات
                      // المعروضة أو الأزرار نفسها.
                      // ══════════════════════════════════════════════════
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () =>
                                    _showProductDialog(context, existing: p),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _confirmDelete(p),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${p.pricesCount} سعر',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(p.avgPrice / 1000).toStringAsFixed(0)},000 ل.س',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STORES SCREEN
// ✅ الآن يقرأ من StoreProvider، وزر التوثيق فعلي (يستدعي
// StoreProvider.setVerified). فلتر الكتلة الإدارية الرسمية بالإضافة
// إلى فلتر التوثيق، وشارة الكتلة تُعرض أسفل كل متجر (مُشتقّة تلقائياً من
// حقل area عبر AleppoBlocks.blockOfArea).
// ✅ جديد — فلتر الحي بجانب فلتر الكتلة الإدارية، يظهر فقط بعد اختيار كتلة.
// ══════════════════════════════════════════════════════════════════════════════
class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});
  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  String _verifyFilter = 'الكل';
  // ✅ فلتر الكتلة الإدارية، يُشتق تصنيف كل متجر تلقائياً من حقل
  // area الموجود أصلاً عبر AleppoBlocks.blockOfArea (بلا حاجة لتعديل الـ
  // model أو الـ backend).
  String _blockFilter = 'الكل';
  // ✅ جديد — فلتر الحي، يظهر فقط بعد اختيار كتلة إدارية محددة، ويُعاد
  // ضبطه تلقائياً إلى "الكل" كلما تغيّرت الكتلة.
  String _areaFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadStores();
      final catalog = context.read<CatalogProvider>();
      if (catalog.locations.isEmpty) catalog.loadLocations();
    });
  }

  Future<void> _toggleVerify(StoreModel s) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<StoreProvider>().setVerified(
          s.id,
          !s.isVerified,
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم تحديث حالة التوثيق' : 'تعذّر التحديث'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ✅ جديد — إضافة متجر مباشرة من لوحة الإدارة. كانت "إدارة المتاجر" هي
  // الشاشة الإدارية الوحيدة التي لا تملك زر "إضافة" رغم أن مخطط حالات
  // الاستخدام يُدرج صراحة أن "إدارة المتاجر" تتضمّن الميزات المشتركة
  // الخمس (عرض/إضافة/تعديل/بحث/حذف) تماماً مثل إدارة المنتجات والمواقع
  // والوحدات والعلامات التجارية والأسعار الرسمية — التي تملك جميعها زر
  // إضافة في رأسها بالفعل. تستخدم نفس منتقي الموقع الموحّد ونفس آلية
  // ترجمة الحي المختار إلى location_id حقيقي عبر
  // CatalogProvider.locationIdForArea، بنفس منطق _showEditStore أدناه
  // وAddStoreScreen (مسار المستخدم العادي) تماماً.
  // ══════════════════════════════════════════════════════════════════════
  void _showAddStore(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String? selectedBlock;
    String? selectedArea;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إضافة متجر جديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسم المتجر', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: nameCtrl,
                      textDirection: TextDirection.rtl,
                      decoration:
                          const InputDecoration(hintText: 'مثال: محل الأمانة')),
                  const SizedBox(height: 14),
                  const Text('العنوان', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: addressCtrl,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                          hintText: 'مثال: شارع الفرقان الرئيسي')),
                  const SizedBox(height: 14),
                  const Text('الكتلة والمنطقة', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showLocationPickerSheet(
                      context,
                      currentBlock: selectedBlock ?? '',
                      currentArea: selectedArea ?? '',
                      onSelect: (block, area) => setDialogState(() {
                        selectedBlock = block;
                        selectedArea = area;
                      }),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderOf(ctx)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedArea == null
                            ? 'اختر الكتلة الإدارية والمنطقة'
                            : AleppoBlocks.displayLabel(
                                block: selectedBlock!, area: selectedArea!),
                        style: TextStyle(
                            color: selectedArea == null
                                ? AppColors.textHintOf(ctx)
                                : AppColors.textPrimaryOf(ctx)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            addressCtrl.text.trim().isEmpty ||
                            selectedArea == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى تعبئة كل الحقول بشكل صحيح'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        final locationId = context
                            .read<CatalogProvider>()
                            .locationIdForArea(selectedArea!);
                        final navigator = Navigator.of(ctx);
                        final ok =
                            await context.read<StoreProvider>().createStore(
                                  name: nameCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                  area: selectedArea!,
                                  sector: selectedBlock!,
                                  locationId: locationId,
                                );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(ok ? 'تمت إضافة المتجر' : 'تعذّرت الإضافة'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('إضافة'),
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ),
      ),
    );
  }

  /// ✅ جديد — تعديل بيانات متجر (الاسم/العنوان/الموقع)، مطابقةً لعنصر
  /// "تعديل" الناقص سابقاً في مخطط حالات الاستخدام لـ"إدارة المتاجر".
  void _showEditStore(StoreModel s) {
    final nameCtrl = TextEditingController(text: s.name);
    final addressCtrl = TextEditingController(text: s.address);
    String? selectedBlock = AleppoBlocks.blockOfArea(s.area)?.name;
    String? selectedArea = s.area;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('تعديل المتجر',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسم المتجر', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: nameCtrl, textDirection: TextDirection.rtl),
                  const SizedBox(height: 14),
                  const Text('العنوان', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: addressCtrl,
                      textDirection: TextDirection.rtl),
                  const SizedBox(height: 14),
                  const Text('الكتلة والمنطقة', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showLocationPickerSheet(
                      context,
                      currentBlock: selectedBlock ?? '',
                      currentArea: selectedArea ?? '',
                      onSelect: (block, area) => setDialogState(() {
                        selectedBlock = block;
                        selectedArea = area;
                      }),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderOf(ctx)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedArea == null
                            ? 'اختر الكتلة والمنطقة'
                            : AleppoBlocks.displayLabel(
                                block: selectedBlock!, area: selectedArea!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            addressCtrl.text.trim().isEmpty) {
                          return;
                        }
                        final locationId = selectedArea == s.area
                            ? null // لم يتغيّر الموقع
                            : context
                                .read<CatalogProvider>()
                                .locationIdForArea(selectedArea!);
                        final navigator = Navigator.of(ctx);
                        final ok =
                            await context.read<StoreProvider>().updateStore(
                                  s.id,
                                  name: nameCtrl.text.trim(),
                                  address: addressCtrl.text.trim(),
                                  locationId: locationId,
                                );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(ok ? 'تم تعديل المتجر' : 'تعذّر التعديل'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ),
      ),
    );
  }

  /// ✅ جديد — حذف متجر، مطابقةً لعنصر "حذف" الناقص سابقاً في نفس المخطط.
  Future<void> _confirmDeleteStore(StoreModel s) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف المتجر',
      message: 'هل تريد حذف "${s.name}" نهائياً؟',
      confirmText: 'حذف',
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<StoreProvider>().deleteStore(s.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'تم حذف المتجر' : 'تعذّر حذف المتجر'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    var stores = _verifyFilter == 'موثق'
        ? storeProvider.stores.where((s) => s.isVerified).toList()
        : _verifyFilter == 'غير موثق'
            ? storeProvider.stores.where((s) => !s.isVerified).toList()
            : storeProvider.stores;
    if (_blockFilter != 'الكل') {
      stores = stores
          .where((s) => AleppoBlocks.blockOfArea(s.area)?.name == _blockFilter)
          .toList();
    }
    // ✅ جديد — فلترة إضافية حسب الحي المحدد
    if (_areaFilter != 'الكل') {
      stores = stores.where((s) => s.area == _areaFilter).toList();
    }

    return Column(
      children: [
        // ✅ إصلاح جوهري — أُضيف زر "إضافة متجر" (كان غائباً تماماً)
        // مطابقةً لمخطط حالات الاستخدام الذي يُدرج "إدارة المتاجر" ضمن
        // الشاشات التي تتضمّن الميزات المشتركة الخمس كاملة (عرض/إضافة/
        // تعديل/بحث/حذف)، بنفس نمط بقية شاشات لوحة الإدارة.
        _AdminGradientHeader(
          title: 'إدارة المتاجر',
          subtitle: 'راجع وتحقق من المتاجر المسجلة، وأضف متاجر جديدة مباشرة',
          icon: Icons.store_outlined,
          actionLabel: 'إضافة متجر',
          onAction: () => _showAddStore(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaffirSearchField(
                hint: 'ابحث عن متجر أو عنوان...',
                onChanged: (v) =>
                    context.read<StoreProvider>().loadStores(search: v),
              ),
              const SizedBox(height: 10),
              // فلتر الكتلة الإدارية
              FilterChipRow(
                options: ['الكل', ...AleppoBlocks.blockNames],
                selected: _blockFilter,
                onSelected: (v) => setState(() {
                  _blockFilter = v;
                  // ✅ إعادة ضبط فلتر الحي تلقائياً عند تغيير الكتلة
                  _areaFilter = 'الكل';
                }),
              ),
              // ✅ جديد — صف فلترة الحي (يظهر فقط بعد اختيار كتلة محددة)
              if (_blockFilter != 'الكل') ...[
                const SizedBox(height: 8),
                FilterChipRow(
                  options: [
                    'الكل',
                    ...AleppoBlocks.areasOfBlock(_blockFilter),
                  ],
                  selected: _areaFilter,
                  onSelected: (v) => setState(() => _areaFilter = v),
                ),
              ],
              const SizedBox(height: 8),
              FilterChipRow(
                options: const ['الكل', 'موثق', 'غير موثق'],
                selected: _verifyFilter,
                onSelected: (v) => setState(() => _verifyFilter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: storeProvider.isLoading && stores.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : stores.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد متاجر مطابقة',
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stores.length,
                      itemBuilder: (ctx, i) {
                        final s = stores[i];
                        final block =
                            AleppoBlocks.blockOfArea(s.area)?.name ?? s.sector;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.borderOf(context)),
                          ),
                          // ══════════════════════════════════════════════
                          // ✅ إصلاح فيضان النص (overflow) جوهري — كانت
                          // البطاقة صفاً واحداً مزدحماً بعناصر ثابتة العرض
                          // بلا حد أقصى للأسطر (اسم المتجر، اسم الحي، عدّاد
                          // الأسعار، شارة التوثيق، زرّا التعديل/الحذف)، فحين
                          // يطول اسم المتجر أو الحي (مثال: "الحمدانية الحي
                          // الأول") يضيق الحيّز المتبقي لنص العنوان (Expanded)
                          // حتى الانضغاط والالتفاف حرفاً حرفاً عمودياً، مع
                          // فيضان فعلي لبقية الصف عن حدود الشاشة
                          // ("RIGHT OVERFLOWED" في وضع التصحيح).
                          //
                          // الحل: إعادة ترتيب البطاقة على 3 صفوف، وكل نص
                          // متغيّر الطول محدود الآن بسطر واحد وعلامة "..."
                          // عند الحاجة (اسم المتجر، العنوان، اسم الحي)، بلا
                          // أي فقدان لأي معلومة كانت معروضة سابقاً:
                          //   1) اسم المتجر (Expanded) + عدد الأسعار + تعديل/حذف
                          //   2) العنوان الكامل بسطر واحد
                          //   3) شارة التوثيق (قابلة للنقر) + شارتا الحي/الكتلة
                          // ══════════════════════════════════════════════
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${s.pricesCount} سعر',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 6),
                                  // ✅ أزرار تعديل/حذف
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    onPressed: () => _showEditStore(s),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16, color: AppColors.error),
                                    onPressed: () => _confirmDeleteStore(s),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _toggleVerify(s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (s.isVerified
                                                ? AppColors.success
                                                : AppColors.textHint)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            s.isVerified
                                                ? Icons.verified
                                                : Icons.help_outline,
                                            size: 14,
                                            color: s.isVerified
                                                ? AppColors.success
                                                : AppColors.textHint,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.isVerified ? 'موثق' : 'توثيق',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: s.isVerified
                                                  ? AppColors.success
                                                  : AppColors.textSecondaryOf(
                                                      context,
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // ✅ شارتا الحي والكتلة الإدارية داخل Wrap
                                  // مرن بدل Row ثابت، فلا تفيضان عن الشاشة
                                  // مهما طال اسم الحي.
                                  Expanded(
                                    child: Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 140),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            s.area,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        // ✅ شارة الكتلة الإدارية
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 140),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            block,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LOCATIONS SCREEN
// ✅ من CatalogProvider، بالإضافة إلى فلتر الكتلة الإدارية وقائمتين
// منسدلتين مترابطتين (كتلة ← حي) عند إضافة موقع جديد بدل حقول نصية حرة.
// ✅ جديد — فلتر الحي بجانب فلتر الكتلة الإدارية في قائمة العرض نفسها،
// يظهر فقط بعد اختيار كتلة، ويُعاد ضبطه عند تغييرها.
// ══════════════════════════════════════════════════════════════════════════════
class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});
  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  // ✅ فلترة قائمة المواقع حسب الكتلة الإدارية
  String _blockFilter = 'الكل';
  // ✅ جديد — فلترة إضافية حسب الحي داخل الكتلة المختارة
  String _areaFilter = 'الكل';
  // ✅ جديد — نص البحث المربوط فعلياً بحقل البحث (كان زخرفياً بلا فلترة)
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadLocations();
    });
  }

  // ✅ إصلاح جوهري: كانت "الإضافة" تعتمد على حقلين نصيين حرّين (القطاع
  // والمنطقة) بلا أي تحقق من مطابقتهما للتقسيم الإداري الرسمي، ما يسمح
  // بإدخال أي نص عشوائي. الآن قائمتان منسدلتان مترابطتان: الكتلة أولاً، ثم
  // الحي الذي يُبنى تلقائياً من أحياء تلك الكتلة فقط (aleppo_blocks.dart)،
  // بالإضافة إلى حقل "المعلم" الحر لوصف تفاصيل إضافية (شارع، دوار...).
  //
  // ✅ محدَّث — أصبحت نافذة موحّدة إضافة/تعديل: تمرير [existing] يحوّلها
  // لنافذة تعديل (CatalogProvider.updateLocation)، مطابقةً لعنصر "تعديل"
  // الناقص سابقاً في مخطط حالات الاستخدام لـ"إدارة المواقع والكتل".
  void _showLocationDialog(BuildContext context, {LocationModel? existing}) {
    final isEdit = existing != null;
    final landmarkCtrl = TextEditingController(text: existing?.landmark ?? '');
    String selectedBlock = existing?.sector ?? AleppoBlocks.all.first.name;
    final _areasForBlock = AleppoBlocks.areasOfBlock(selectedBlock);
    String selectedArea = existing?.area ??
        (_areasForBlock.isNotEmpty
            ? _areasForBlock.first
            : AleppoBlocks.all.first.areas.first);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEdit ? 'تعديل الموقع' : 'إضافة موقع جديد',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الكتلة الإدارية',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBlock,
                    isExpanded: true,
                    items: AleppoBlocks.blockNames
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        selectedBlock = v;
                        // ✅ إعادة ضبط الحي تلقائياً عند تغيير الكتلة
                        selectedArea = AleppoBlocks.areasOfBlock(v).first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('المنطقة', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(selectedBlock),
                    initialValue: selectedArea,
                    isExpanded: true,
                    items: AleppoBlocks.areasOfBlock(selectedBlock)
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedArea = v ?? selectedArea),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'المعلم (اختياري)',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: landmarkCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      hintText: 'مثال: شارع بغداد',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(ctx);
                        final provider = context.read<CatalogProvider>();
                        final ok = isEdit
                            ? await provider.updateLocation(
                                existing.id,
                                sector: selectedBlock,
                                area: selectedArea,
                                landmark: landmarkCtrl.text.trim(),
                              )
                            : await provider.addLocation(
                                sector: selectedBlock,
                                area: selectedArea,
                                landmark: landmarkCtrl.text.trim(),
                              );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? (isEdit ? 'تم التعديل' : 'تمت الإضافة')
                                  : (isEdit
                                      ? 'تعذّر التعديل'
                                      : 'تعذّرت الإضافة'),
                            ),
                            backgroundColor:
                                ok ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(isEdit ? 'حفظ' : 'إضافة'),
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ),
      ),
    );
  }

  /// ✅ جديد — حذف موقع، مطابقةً لعنصر "حذف" الناقص سابقاً في نفس المخطط.
  Future<void> _confirmDeleteLocation(LocationModel l) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف الموقع',
      message: 'هل تريد حذف "${l.area}" نهائياً؟',
      confirmText: 'حذف',
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<CatalogProvider>().deleteLocation(l.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'تم حذف الموقع' : 'تعذّر حذف الموقع'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    var locations = _blockFilter == 'الكل'
        ? catalog.locations
        : catalog.locations.where((l) => l.sector == _blockFilter).toList();
    // ✅ جديد — فلترة إضافية حسب الحي المحدد
    if (_areaFilter != 'الكل') {
      locations = locations.where((l) => l.area == _areaFilter).toList();
    }
    // ✅ إصلاح — كان حقل البحث زخرفياً بلا onChanged
    if (_search.trim().isNotEmpty) {
      final q = _search.trim();
      locations = locations
          .where((l) => l.area.contains(q) || l.landmark.contains(q))
          .toList();
    }

    return Column(
      children: [
        _AdminGradientHeader(
          title: 'إدارة المواقع والكتل',
          subtitle: 'أدر الكتل الإدارية الخمس وأحياءها',
          icon: Icons.location_on_outlined,
          actionLabel: 'إضافة موقع',
          onAction: () => _showLocationDialog(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaffirSearchField(
                hint: 'ابحث عن حي أو معلم...',
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              // ✅ فلترة حسب الكتلة الإدارية
              FilterChipRow(
                options: ['الكل', ...AleppoBlocks.blockNames],
                selected: _blockFilter,
                onSelected: (v) => setState(() {
                  _blockFilter = v;
                  // ✅ إعادة ضبط فلتر الحي تلقائياً عند تغيير الكتلة
                  _areaFilter = 'الكل';
                }),
              ),
              // ✅ جديد — صف فلترة الحي (يظهر فقط بعد اختيار كتلة محددة)
              if (_blockFilter != 'الكل') ...[
                const SizedBox(height: 8),
                FilterChipRow(
                  options: [
                    'الكل',
                    ...AleppoBlocks.areasOfBlock(_blockFilter),
                  ],
                  selected: _areaFilter,
                  onSelected: (v) => setState(() => _areaFilter = v),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: catalog.isLoading && catalog.locations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : locations.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد مواقع مطابقة',
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: locations.length,
                      itemBuilder: (ctx, i) {
                        final l = locations[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.borderOf(context)),
                          ),
                          // ══════════════════════════════════════════════
                          // ✅ إصلاح فيضان النص (overflow) جوهري — كان اسم
                          // الحي (l.area) نصاً غير مرن بلا حد أقصى للأسطر،
                          // فحين يطول (مثال: "الحمدانية الحي الأول") يضيق
                          // الحيّز المتبقي لنص "المعلم" (Expanded) لدرجة
                          // تجعله يلتف حرفاً حرفاً عمودياً بجانب فيضان فعلي
                          // للصف كاملاً عن حدود الشاشة. الحل: صفان منفصلان —
                          // الأول لاسم الحي (Expanded) + عدد المتاجر + زرّي
                          // التعديل/الحذف، والثاني لشارة الكتلة + المعلم،
                          // وكل نص متغيّر الطول محدود الآن بسطر واحد مع "..."
                          // عند الحاجة.
                          // ══════════════════════════════════════════════
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.area,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${l.storesCount}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // ✅ أزرار تعديل/حذف، مطابقةً لمخطط حالات
                                  // الاستخدام لـ"إدارة المواقع والكتل".
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    onPressed: () => _showLocationDialog(
                                        context,
                                        existing: l),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16, color: AppColors.error),
                                    onPressed: () => _confirmDeleteLocation(l),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // ✅ شارة الكتلة الإدارية بدل نص "حلب" العام
                                  // السابق
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 130),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l.sector,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      l.landmark,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// UNITS SCREEN — ✅ من CatalogProvider، إضافة/حذف فعليان
// ══════════════════════════════════════════════════════════════════════════════
class AdminUnitsScreen extends StatefulWidget {
  const AdminUnitsScreen({super.key});
  @override
  State<AdminUnitsScreen> createState() => _AdminUnitsScreenState();
}

class _AdminUnitsScreenState extends State<AdminUnitsScreen> {
  // ✅ جديد — حقل بحث لم يكن موجوداً إطلاقاً سابقاً رغم إدراجه ضمن الأفعال
  // الموحّدة في مخطط حالات الاستخدام لـ"إدارة الوحدات".
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadUnits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final units = _search.trim().isEmpty
        ? catalog.units
        : catalog.units.where((u) => u.name.contains(_search.trim())).toList();
    return Column(
      children: [
        _AdminGradientHeader(
          title: 'إدارة الوحدات',
          subtitle: 'أدر وحدات القياس المستخدمة في النظام',
          icon: Icons.tag,
          actionLabel: 'إضافة وحدة',
          onAction: () async {
            final name = await showAddDialog(
              context,
              title: 'إضافة وحدة جديدة',
              fieldLabel: 'اسم الوحدة',
              hint: 'مثال: كيلوغرام',
            );
            if (name == null || name.trim().isEmpty || !mounted) return;
            final ok = await context.read<CatalogProvider>().addUnit(
                  name.trim(),
                );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok ? 'تمت الإضافة' : 'تعذّرت الإضافة'),
                backgroundColor: ok ? AppColors.success : AppColors.error,
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WaffirSearchField(
            hint: 'ابحث عن وحدة...',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: catalog.isLoading && catalog.units.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: units.length,
                  itemBuilder: (ctx, i) {
                    final u = units[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final confirmed = await showConfirmDialog(
                                    ctx,
                                    title: 'حذف الوحدة',
                                    message: 'هل تريد حذف هذه الوحدة؟',
                                    confirmText: 'حذف',
                                    icon: Icons.delete_outline,
                                  );
                                  if (confirmed == true && mounted) {
                                    await context
                                        .read<CatalogProvider>()
                                        .deleteUnit(u.id);
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                // ✅ إصلاح جوهري — أصبح endpoint التعديل موثّقاً
                                // فعلياً (PUT /units/{id}، راجع CatalogService.
                                // updateUnit)، فحلّت نافذة تعديل حقيقية محل
                                // رسالة "قيد التطوير" السابقة.
                                onPressed: () async {
                                  final name = await showAddDialog(
                                    context,
                                    title: 'تعديل الوحدة',
                                    fieldLabel: 'اسم الوحدة',
                                    hint: 'مثال: كيلوغرام',
                                    initialValue: u.name,
                                    confirmLabel: 'حفظ',
                                  );
                                  if (name == null ||
                                      name.trim().isEmpty ||
                                      !mounted) {
                                    return;
                                  }
                                  final ok = await context
                                      .read<CatalogProvider>()
                                      .updateUnit(u.id, name.trim());
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          ok ? 'تم التعديل' : 'تعذّر التعديل'),
                                      backgroundColor: ok
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${u.usageCount} استخدام',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.tag,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BRANDS SCREEN — ✅ من CatalogProvider، إضافة/حذف فعليان
// ══════════════════════════════════════════════════════════════════════════════
class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});
  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  // ✅ جديد — حقل بحث لم يكن موجوداً إطلاقاً سابقاً
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadBrands();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final brands = _search.trim().isEmpty
        ? catalog.brands
        : catalog.brands.where((b) => b.name.contains(_search.trim())).toList();
    return Column(
      children: [
        _AdminGradientHeader(
          title: 'إدارة العلامات التجارية',
          subtitle: 'أدر العلامات التجارية في النظام',
          icon: Icons.label_outlined,
          actionLabel: 'إضافة علامة',
          onAction: () async {
            final name = await showAddDialog(
              context,
              title: 'إضافة علامة تجارية جديدة',
              fieldLabel: 'اسم العلامة التجارية',
              hint: 'مثال: فلسطين',
            );
            if (name == null || name.trim().isEmpty || !mounted) return;
            final ok = await context.read<CatalogProvider>().addBrand(
                  name.trim(),
                );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok ? 'تمت الإضافة' : 'تعذّرت الإضافة'),
                backgroundColor: ok ? AppColors.success : AppColors.error,
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WaffirSearchField(
            hint: 'ابحث عن علامة تجارية...',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: catalog.isLoading && catalog.brands.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: brands.length,
                  itemBuilder: (ctx, i) {
                    final b = brands[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final confirmed = await showConfirmDialog(
                                    ctx,
                                    title: 'حذف العلامة التجارية',
                                    message: 'هل تريد حذف هذه العلامة؟',
                                    confirmText: 'حذف',
                                    icon: Icons.delete_outline,
                                  );
                                  if (confirmed == true && mounted) {
                                    await context
                                        .read<CatalogProvider>()
                                        .deleteBrand(b.id);
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                // ✅ إصلاح جوهري — أصبح endpoint التعديل موثّقاً
                                // فعلياً (PUT /brands/{id})، فحلّت نافذة تعديل
                                // حقيقية محل رسالة "قيد التطوير" السابقة.
                                onPressed: () async {
                                  final name = await showAddDialog(
                                    context,
                                    title: 'تعديل العلامة التجارية',
                                    fieldLabel: 'اسم العلامة التجارية',
                                    hint: 'مثال: فلسطين',
                                    initialValue: b.name,
                                    confirmLabel: 'حفظ',
                                  );
                                  if (name == null ||
                                      name.trim().isEmpty ||
                                      !mounted) {
                                    return;
                                  }
                                  final ok = await context
                                      .read<CatalogProvider>()
                                      .updateBrand(b.id, name.trim());
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          ok ? 'تم التعديل' : 'تعذّر التعديل'),
                                      backgroundColor: ok
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${b.productsCount} منتج',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.label_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// OFFICIAL PRICES SCREEN — ✅ من CatalogProvider، إضافة فعلية
//
// ✅ إصلاح جوهري في نافذة "إضافة سعر رسمي جديد" (بلا أي تغيير في شكل
// النافذة أو ترتيب حقولها): كان حقلا "المنتج" و"الوحدة" عبارة عن نص حر
// (TextField)، رغم أن مخطط قاعدة البيانات الفعلي لجدول OfficialPrice لا
// يحتوي أي عمود نصي لاسم المنتج أو الوحدة — فقط product_id/unit_id
// (مفتاحان أجنبيان يشيران لجدولي Product/Unit). أي اسم يُكتب يدوياً لا
// يملك أي ربط حقيقي بقاعدة البيانات ولا يمكن للخادم حفظه بشكل صحيح.
//
// استُبدل ذلك بقائمتين منسدلتين (نفس نمط _showAddLocation أعلاه تماماً):
// "المنتج" تُختار من ProductProvider.products الحقيقية، و"الوحدة" من
// CatalogProvider.units الحقيقية — بنفس عنوان النافذة، ونفس ترتيب الحقول
// (المنتج، الكمية، الوحدة، السعر)، ونفس شكل وحجم الأزرار تماماً.
// ══════════════════════════════════════════════════════════════════════════════
class AdminOfficialPricesScreen extends StatefulWidget {
  const AdminOfficialPricesScreen({super.key});
  @override
  State<AdminOfficialPricesScreen> createState() =>
      _AdminOfficialPricesScreenState();
}

class _AdminOfficialPricesScreenState extends State<AdminOfficialPricesScreen> {
  // ✅ جديد — نص البحث المربوط فعلياً (كان حقل البحث زخرفياً بلا فلترة)
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadOfficialPrices();
    });
  }

  /// ✅ محدَّث — نافذة موحّدة إضافة/تعديل. تمرير [existing] يحوّلها لنافذة
  /// تعديل (CatalogProvider.updateOfficialPrice)، مطابقةً لعنصر "تعديل"
  /// الناقص سابقاً في مخطط حالات الاستخدام لـ"إدارة الأسعار الرسمية".
  void _showOfficialPriceDialog(BuildContext context,
      {OfficialPrice? existing}) {
    final isEdit = existing != null;
    final qtyCtrl = TextEditingController(
        text: (existing?.quantity ?? 1).toStringAsFixed(0));
    final priceCtrl = TextEditingController(
        text: existing != null ? existing.price.toStringAsFixed(0) : '');

    // ✅ تحميل قوائم المنتجات والوحدات الحقيقية (إن لم تكن محمَّلة أصلاً)
    // قبل فتح النافذة، حتى تظهر القائمتان المنسدلتان مملوءتين فوراً.
    final productProvider = context.read<ProductProvider>();
    final catalogProvider = context.read<CatalogProvider>();
    if (productProvider.products.isEmpty) productProvider.loadProducts();
    if (catalogProvider.units.isEmpty) catalogProvider.loadUnits();

    String? selectedProductId = existing?.productId;
    String? selectedUnitId = existing?.unitId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // ✅ watch هنا (لا read) لتحديث محتوى القائمتين فور اكتمال
          // التحميل حتى لو فُتحت النافذة قبل وصول الاستجابة.
          final products = context.watch<ProductProvider>().products;
          final units = context.watch<CatalogProvider>().units;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEdit ? 'تعديل سعر رسمي' : 'إضافة سعر رسمي جديد',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('المنتج', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProductId,
                      isExpanded: true,
                      hint: const Text('اختر المنتج',
                          style: TextStyle(fontSize: 13)),
                      items: products
                          .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedProductId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الكمية',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(hintText: '1'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الوحدة',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedUnitId,
                                isExpanded: true,
                                hint: const Text('اختر',
                                    style: TextStyle(fontSize: 13)),
                                items: units
                                    .map((u) => DropdownMenuItem(
                                        value: u.id,
                                        child: Text(u.name,
                                            style:
                                                const TextStyle(fontSize: 14))))
                                    .toList(),
                                onChanged: (v) =>
                                    setDialogState(() => selectedUnitId = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child:
                          Text('السعر (ل.س)', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final qty = double.tryParse(qtyCtrl.text.trim());
                          final price = double.tryParse(priceCtrl.text.trim());
                          if (selectedProductId == null ||
                              selectedUnitId == null ||
                              qty == null ||
                              price == null) {
                            return;
                          }
                          final productName = products
                              .firstWhere((p) => p.id == selectedProductId)
                              .name;
                          final unitName = units
                              .firstWhere((u) => u.id == selectedUnitId)
                              .name;
                          final navigator = Navigator.of(ctx);
                          final provider = context.read<CatalogProvider>();
                          final ok = isEdit
                              ? await provider.updateOfficialPrice(
                                  existing.id,
                                  productId: selectedProductId!,
                                  productName: productName,
                                  unitId: selectedUnitId!,
                                  unitName: unitName,
                                  amount: qty,
                                  price: price,
                                )
                              : await provider.addOfficialPrice(
                                  productId: selectedProductId!,
                                  productName: productName,
                                  unitId: selectedUnitId!,
                                  unitName: unitName,
                                  amount: qty,
                                  price: price,
                                );
                          navigator.pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? (isEdit ? 'تم التعديل' : 'تمت الإضافة')
                                    : (isEdit
                                        ? 'تعذّر التعديل'
                                        : 'تعذّرت الإضافة'),
                              ),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(isEdit ? 'حفظ' : 'إضافة'),
                      ),
                    ),
                  ],
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        },
      ),
    );
  }

  /// ✅ جديد — حذف سعر رسمي، مطابقةً لعنصر "حذف" الناقص سابقاً في نفس المخطط.
  Future<void> _confirmDeleteOfficialPrice(OfficialPrice op) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف السعر الرسمي',
      message: 'هل تريد حذف السعر الرسمي لـ"${op.productName}" نهائياً؟',
      confirmText: 'حذف',
      icon: Icons.delete_outline,
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<CatalogProvider>().deleteOfficialPrice(op.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'تم الحذف' : 'تعذّر الحذف'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final officialPrices = _search.trim().isEmpty
        ? catalog.officialPrices
        : catalog.officialPrices
            .where((op) => op.productName.contains(_search.trim()))
            .toList();
    return Column(
      children: [
        _AdminGradientHeader(
          title: 'الأسعار الرسمية',
          subtitle: 'أدر الأسعار الرسمية للمنتجات',
          icon: Icons.description_outlined,
          actionLabel: 'إضافة سعر رسمي',
          onAction: () => _showOfficialPriceDialog(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WaffirSearchField(
            hint: 'ابحث عن منتج...',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: catalog.isLoading && catalog.officialPrices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: officialPrices.length,
                  itemBuilder: (ctx, i) {
                    final op = officialPrices[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderOf(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              op.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(op.unit, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            op.quantity.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(op.price / 1000).toStringAsFixed(0)},000 ل.س',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // ✅ جديد — أزرار تعديل/حذف، كانتا غائبتين تماماً
                          // سابقاً رغم إدراجهما في مخطط حالات الاستخدام.
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.textSecondary),
                            onPressed: () =>
                                _showOfficialPriceDialog(context, existing: op),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                            onPressed: () => _confirmDeleteOfficialPrice(op),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ANALYTICS SCREEN
// ✅ الأرقام الثلاثة العلوية أصبحت من CatalogProvider.dashboardStats بدل
// أرقام ثابتة. الرسوم البيانية أدناه تبقى توضيحية عمداً — لا يوجد أي
// endpoint موثّق حالياً يعيد سلاسل بيانات زمنية (chart series)، وهذا موثّق
// بوضوح في docs/API_ADDENDUM.md كنقطة مفتوحة لمطوّر الـ backend.
// ══════════════════════════════════════════════════════════════════════════════
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<CatalogProvider>().dashboardStats;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _AdminGradientHeader(
          title: 'التحليلات والإحصائيات',
          subtitle: 'تتبع الاتجاهات والأنماط في البيانات',
          icon: Icons.bar_chart,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              StatCard(
                icon: Icons.attach_money,
                iconColor: Colors.orange,
                iconBg: Colors.orange.withValues(alpha: 0.1),
                value: '${stats['totalPrices'] ?? '—'}',
                label: 'إجمالي الأسعار',
                growth: stats['pricesGrowth'] != null
                    ? '${stats['pricesGrowth']}%+'
                    : null,
                isPositive: true,
              ),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.people_outlined,
                iconColor: Colors.green,
                iconBg: Colors.green.withValues(alpha: 0.1),
                value: '${stats['totalUsers'] ?? '—'}',
                label: 'إجمالي المستخدمين',
                growth: stats['usersGrowth'] != null
                    ? '${stats['usersGrowth']}%+'
                    : null,
                isPositive: true,
              ),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.purple,
                iconBg: Colors.purple.withValues(alpha: 0.1),
                value: '${stats['totalProducts'] ?? '—'}',
                label: 'إجمالي المنتجات',
                growth: stats['productsGrowth'] != null
                    ? '${stats['productsGrowth']}%+'
                    : null,
                isPositive: true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.textHintOf(context),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'رسم توضيحي — بانتظار endpoint سلاسل بيانات زمنية',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'نشاط الأسعار',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LineChartPlaceholder(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'توزيع الفئات',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PieChartPlaceholder(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنتجات الأكثر نشاطاً',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BarChartPlaceholder(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final points = [300.0, 350.0, 400.0, 450.0, 460.0, 500.0, 700.0];
    return SizedBox(
      height: 160,
      child: CustomPaint(painter: _LineChartPainter(points)),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> points;
  _LineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    const minY = 200.0, maxY = 800.0;

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y =
          size.height - ((points[i] - minY) / (maxY - minY)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PieChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Legend('زيوت (35%)', AppColors.primary),
            const SizedBox(height: 4),
            const _Legend('سكريات (20%)', Colors.lightBlue),
            const SizedBox(height: 4),
            _Legend('أخرى', Colors.blue.shade200),
          ],
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(painter: _PieChartPainter()),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final slices = [
      (0.35, AppColors.primary),
      (0.20, Colors.lightBlue),
      (0.20, Colors.blue.shade200),
      (0.25, AppColors.primaryLight),
    ];
    double start = -3.14159 / 2;
    for (final slice in slices) {
      final sweep = slice.$1 * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()
          ..color = slice.$2
          ..style = PaintingStyle.fill,
      );
      start += sweep;
    }
    canvas.drawCircle(
      center,
      radius * 0.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BarChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = [
      ('رز أبيض', 156),
      ('زيت ذرة', 130),
      ('طحين', 105),
      ('سكر', 95),
    ];
    final maxVal = bars.map((b) => b.$2).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: bars
                .map(
                  (b) => Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 120 * b.$2 / maxVal,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: bars
              .map((b) => Text(b.$1, style: const TextStyle(fontSize: 11)))
              .toList(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// (بلا تغيير جوهري — تعتمد على AppProvider فقط وهو مربوط بالكامل بالفعل)
// ✅ ملاحظة: هذه الشاشة تحديداً لا تُظهر زر تبديل الثيم في شريط العنوان
// العلوي المشترك في AdminShell (راجع _AdminShellState.build أعلاه)، لأنها
// تحتوي أصلاً بطاقة "الوضع الليلي" الخاصة بها أدناه.
// ══════════════════════════════════════════════════════════════════════════════
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  void _showLanguageInfo() {
    showComingSoonDialog(
      context,
      title: 'اللغة',
      message: 'العربية هي اللغة الوحيدة المتوفرة حالياً في لوحة الإدارة. '
          'دعم لغات إضافية (مثل الإنجليزية) مخطط له في إصدار قادم.',
      icon: Icons.language,
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ✅ إصلاح شكل الزر (نفس الإصلاح المطلوب في لقطة الشاشة): كان الزر
  // ElevatedButton بلا تغليف SizedBox عريض، مع minimumSize(0, 40) — القيمة
  // 0 للعرض تجعل الزر ينكمش تماماً على حجم النص فقط فيظهر كحبّة ضيقة غير
  // احترافية. الآن يُغلَّف الزر بـ SizedBox بعرض كامل (double.infinity)
  // وارتفاع أكبر (48)، مع زوايا دائرية أوضح (14) ووزن خط أثقل للنص،
  // بالإضافة إلى actionsPadding متسق مع باقي حوارات التطبيق.
  // ══════════════════════════════════════════════════════════════════════
  void _showAccountInfo(AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('معلومات الحساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
                title: const Text('الاسم'),
                subtitle: Text(provider.userName),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('رقم الهاتف / اسم المستخدم'),
                subtitle: Text(provider.userPhone),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('الصلاحية'),
                subtitle: const Text('مدير النظام'),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('حسناً',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startChangePassword(AppProvider provider) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'تغيير كلمة المرور',
      message: 'سنرسل رمز تحقق عبر رسالة نصية إلى هاتفك ${provider.userPhone} '
          'لتأكيد هويتك قبل تعيين كلمة مرور جديدة.',
      confirmText: 'إرسال الرمز',
      confirmColor: AppColors.primary,
      icon: Icons.lock_reset_outlined,
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.forgotPassword(provider.userPhone);
    if (!mounted) return;
    if (ok) {
      await Navigator.pushNamed(
        context,
        AppRoutes.resetPassword,
        arguments: {'phone': provider.userPhone, 'fromSettings': true},
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'تعذّر إرسال رمز التحقق، حاول مجدداً',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmLogout(AppProvider provider) async {
    final ok = await showConfirmDialog(
      context,
      title: 'تأكيد تسجيل الخروج',
      message: 'هل أنت متأكد من رغبتك في تسجيل الخروج من لوحة الإدارة؟',
      confirmText: 'تسجيل الخروج',
      icon: Icons.logout,
    );
    if (ok == true && mounted) {
      await provider.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.splash,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _AdminGradientHeader(
          title: 'إعدادات الإدارة',
          subtitle: 'أدر تفضيلات وإعدادات لوحة التحكم',
          icon: Icons.settings_outlined,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const _AdminSectionHeader('تفضيلات لوحة التحكم'),
              _AdminCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Switch(
                      value: provider.isDarkMode,
                      onChanged: (_) => provider.toggleDarkMode(),
                      activeThumbColor: AppColors.primary,
                    ),
                    const Row(
                      children: [
                        Text(
                          'الوضع الليلي',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 8),
                        Text('🌙', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const _AdminSectionHeader('الإشعارات'),
              const _AdminNotificationsSection(),
              const _AdminSectionHeader('الأمان'),
              _AdminCard(
                child: _tappableRow(
                  onTap: () => _startChangePassword(provider),
                  label: 'تغيير كلمة المرور',
                  emoji: '🔐',
                ),
              ),
              const _AdminSectionHeader('إعدادات الحساب'),
              _AdminCard(
                child: _tappableRow(
                  onTap: () => _showAccountInfo(provider),
                  label: 'معلومات الحساب',
                  emoji: '👤',
                ),
              ),
              _AdminCard(
                // ══════════════════════════════════════════════════════
                // ✅ إصلاح جوهري — كانت "صلاحيات المسؤولين" مجرد نافذة
                // "قيد التطوير" بلا أي وظيفة فعلية. مخطط حالات الاستخدام
                // يُدرج "عرض المسؤولين" كحالة استخدام مستقلة كاملة ضمن
                // الإعدادات، مع extend إلى: إضافة/تعديل/بحث/حذف مسؤول.
                // الآن تُفتح شاشة AdminAdminsScreen المخصّصة بالكامل لهذا
                // الغرض (راجع أسفل الملف).
                // ══════════════════════════════════════════════════════
                child: _tappableRow(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAdminsScreen()),
                  ),
                  label: 'إدارة المسؤولين',
                  emoji: '🛡️',
                ),
              ),
              _AdminCard(
                child: _tappableRow(
                  onTap: () => _confirmLogout(provider),
                  label: 'تسجيل الخروج',
                  emoji: '🚪',
                  labelColor: AppColors.error,
                ),
              ),
              const _AdminSectionHeader('التطبيق'),
              _AdminCard(
                child: _tappableRow(
                  onTap: _showLanguageInfo,
                  label: 'اللغة',
                  emoji: '🌍',
                  trailingText: 'العربية',
                ),
              ),
              _AdminCard(
                child: _tappableRow(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                  label: 'سياسة الخصوصية',
                  emoji: '🛡',
                ),
              ),
              _AdminCard(
                child: _tappableRow(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.termsOfService),
                  label: 'الشروط والأحكام',
                  emoji: '📋',
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'نظام إدارة وفّر\nالإصدار 1.0.0',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tappableRow({
    required VoidCallback onTap,
    required String label,
    required String emoji,
    String? trailingText,
    Color? labelColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.arrow_back_ios,
                size: 14,
                color: labelColor ?? AppColors.textHint,
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 4),
                Text(
                  trailingText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(emoji, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminNotificationsSection extends StatefulWidget {
  const _AdminNotificationsSection();
  @override
  State<_AdminNotificationsSection> createState() =>
      _AdminNotificationsSectionState();
}

class _AdminNotificationsSectionState
    extends State<_AdminNotificationsSection> {
  bool _emailNotif = true;
  bool _priceNotif = true;
  bool _reportNotif = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _emailNotif = prefs.getBool('admin_notif_email') ?? true;
      _priceNotif = prefs.getBool('admin_notif_price') ?? true;
      _reportNotif = prefs.getBool('admin_notif_report') ?? true;
    });
  }

  Future<void> _set(String key, bool value, VoidCallback apply) async {
    setState(apply);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        (
          _emailNotif,
          'إشعارات البريد الإلكتروني',
          '📧',
          (bool v) {
            _set('admin_notif_email', v, () => _emailNotif = v);
          },
        ),
        (
          _priceNotif,
          'تنبيهات الأسعار الجديدة',
          '💰',
          (bool v) {
            _set('admin_notif_price', v, () => _priceNotif = v);
          },
        ),
        (
          _reportNotif,
          'تنبيهات البلاغات',
          '🚨',
          (bool v) {
            _set('admin_notif_report', v, () => _reportNotif = v);
          },
        ),
      ]
          .map(
            (item) => _AdminCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Switch(
                    value: item.$1,
                    onChanged: item.$4,
                    activeThumbColor: AppColors.primary,
                  ),
                  Row(
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Text(item.$3, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  final String text;
  const _AdminSectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondaryOf(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _AdminCard extends StatelessWidget {
  final Widget child;
  const _AdminCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: child,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ جديد بالكامل — ADMINS SCREEN ("عرض المسؤولين")
// حالة استخدام مستقلة كانت غائبة تماماً عن التطبيق رغم وجودها صراحة في
// مخطط حالات الاستخدام ضمن قسم الإعدادات، مع extend إلى: إضافة مسؤول،
// تعديل معلومات مسؤول، البحث عن مسؤول، حذف مسؤول.
//
// ✅ ملاحظة تصميمية مهمة: جدول User في قاعدة البيانات الفعلية
// (Waffir_Database.txt) لا يحتوي جدولاً منفصلاً للمسؤولين — الأدوار كلها
// أعمدة role على نفس جدول User. لذا "المسؤولون" هنا هم ببساطة مستخدمون
// بقيمة role مرتفعة (راجع UserModel._parseRole في models.dart)، وتُبنى
// هذه الشاشة فوق نفس AdminUsersProvider المستخدم في "إدارة المستخدمين"
// (دون طلب شبكة منفصل):
//   • عرض  → AdminUsersProvider.admins (مُشتقّة من users المُحمَّلة)
//   • بحث  → فلترة محلية على الاسم/الهاتف
//   • إضافة → AdminUsersProvider.createUser(role: 'admin') — إنشاء حساب
//             مسؤول جديد مباشرة من هنا
//   • تعديل → AdminUsersProvider.updateUser (تعديل الاسم)
//   • حذف  → تُفسَّر هنا كـ"إزالة صلاحية الإدارة" (إعادة الدور إلى
//             'user' عبر setRole) وليس حذف الحساب بالكامل، لتفادي حذف
//             مستخدم قد يملك محتوى مرتبطاً به (أسعار، بلاغات...) بصورة
//             لا رجعة فيها من نافذة لا علاقة موضوعها بذلك مباشرة. إن أراد
//             ohayo لاحقاً حذفاً فعلياً للحساب بدل التخفيض، يمكن استبدال
//             الاستدعاء بسهولة بـ AdminUsersProvider.deleteUser.
// ══════════════════════════════════════════════════════════════════════════════
class AdminAdminsScreen extends StatefulWidget {
  const AdminAdminsScreen({super.key});

  @override
  State<AdminAdminsScreen> createState() => _AdminAdminsScreenState();
}

class _AdminAdminsScreenState extends State<AdminAdminsScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminUsersProvider>();
      if (provider.users.isEmpty) provider.loadUsers();
      final catalog = context.read<CatalogProvider>();
      if (catalog.locations.isEmpty) catalog.loadLocations();
    });
  }

  void _showEditAdmin(UserModel admin) {
    final nameCtrl = TextEditingController(text: admin.name);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل معلومات المسؤول',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الاسم الكامل', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final navigator = Navigator.of(ctx);
                      final ok = await context
                          .read<AdminUsersProvider>()
                          .updateUser(admin.id, name: nameCtrl.text.trim());
                      navigator.pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(ok ? 'تم تحديث البيانات' : 'تعذّر التحديث'),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.error,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero),
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ),
    );
  }

  Future<void> _confirmRemoveAdmin(UserModel admin) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف مسؤول',
      message:
          'هل تريد إزالة "${admin.name}" من قائمة المسؤولين؟ سيعود حسابه إلى صلاحية مستخدم عادي.',
      confirmText: 'حذف',
      icon: Icons.person_remove_outlined,
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok =
        await context.read<AdminUsersProvider>().setRole(admin.id, 'user');
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'تم حذف المسؤول' : 'تعذّر تنفيذ الإجراء'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  void _showAddAdmin(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? selectedBlock;
    String? selectedArea;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إضافة مسؤول جديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الاسم الكامل', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: nameCtrl, textDirection: TextDirection.rtl),
                  const SizedBox(height: 14),
                  const Text('رقم الهاتف', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr),
                  const SizedBox(height: 14),
                  const Text('كلمة المرور المبدئية',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(controller: passwordCtrl, obscureText: true),
                  const SizedBox(height: 14),
                  const Text('الكتلة والمنطقة', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showLocationPickerSheet(
                      context,
                      currentBlock: selectedBlock ?? '',
                      currentArea: selectedArea ?? '',
                      onSelect: (block, area) => setDialogState(() {
                        selectedBlock = block;
                        selectedArea = area;
                      }),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderOf(ctx)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedArea == null
                            ? 'اختر الكتلة الإدارية والمنطقة'
                            : AleppoBlocks.displayLabel(
                                block: selectedBlock!, area: selectedArea!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            passwordCtrl.text.trim().length < 6 ||
                            selectedArea == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يرجى تعبئة كل الحقول بشكل صحيح'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        final locationId = context
                            .read<CatalogProvider>()
                            .locationIdForArea(selectedArea!);
                        final navigator = Navigator.of(ctx);
                        final ok =
                            await context.read<AdminUsersProvider>().createUser(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  password: passwordCtrl.text,
                                  locationId: locationId ?? '',
                                  role: 'admin',
                                );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(ok ? 'تمت إضافة المسؤول' : 'تعذّرت الإضافة'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero),
                      child: const Text('إضافة'),
                    ),
                  ),
                ],
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminUsersProvider>();
    final admins = _search.trim().isEmpty
        ? provider.admins
        : provider.admins
            .where((a) =>
                a.name.contains(_search.trim()) ||
                a.phone.contains(_search.trim()))
            .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المسؤولين'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _AdminGradientHeader(
              title: 'عرض المسؤولين',
              subtitle: 'أدر حسابات المسؤولين وصلاحياتهم',
              icon: Icons.shield_outlined,
              actionLabel: 'إضافة مسؤول',
              onAction: () => _showAddAdmin(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WaffirSearchField(
                hint: 'ابحث عن اسم أو رقم هاتف مسؤول...',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: provider.isLoading && provider.users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : admins.isEmpty
                      ? Center(
                          child: Text('لا يوجد مسؤولون مطابقون',
                              style: TextStyle(
                                  color: AppColors.textSecondaryOf(context))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: admins.length,
                          itemBuilder: (ctx, i) {
                            final a = admins[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceOf(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.borderOf(context)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.purple.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.shield_outlined,
                                        size: 16, color: Colors.purple),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(a.name,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        Text(a.phone,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondaryOf(
                                                        context))),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                    onPressed: () => _showEditAdmin(a),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.person_remove_outlined,
                                        size: 18,
                                        color: AppColors.error),
                                    onPressed: () => _confirmRemoveAdmin(a),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
