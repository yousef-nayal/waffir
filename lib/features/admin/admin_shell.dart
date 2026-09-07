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
// فعلية تستدعي PriceProvider.review() (كانت الشاشة سابقاً جدولاً للعرض فقط
// بلا أي إجراء).
// ✅ جديد — فلتر الحي بجانب فلتر الكتلة الإدارية، يظهر فقط بعد اختيار كتلة.
// ══════════════════════════════════════════════════════════════════════════════
class AdminPriceReviewScreen extends StatefulWidget {
  const AdminPriceReviewScreen({super.key});
  @override
  State<AdminPriceReviewScreen> createState() => _AdminPriceReviewScreenState();
}

class _AdminPriceReviewScreenState extends State<AdminPriceReviewScreen> {
  String _filter = 'الكل';
  // ✅ فلتر الكتلة الإدارية، يُشتق تصنيف كل سعر تلقائياً من حقل
  // e.storeArea الموجود أصلاً في PriceEntry عبر AleppoBlocks.blockOfArea
  // (بلا حاجة لتعديل الـ model أو الـ backend).
  String _blockFilter = 'الكل';
  // ✅ جديد — فلتر الحي، يظهر فقط بعد اختيار كتلة إدارية محددة، ويُعاد
  // ضبطه تلقائياً إلى "الكل" كلما تغيّرت الكتلة.
  String _areaFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PriceProvider>().loadAdminPrices();
    });
  }

  Future<void> _review(PriceEntry e, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<PriceProvider>().review(
          e.id,
          approve: approve,
        );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approve ? 'تمت الموافقة على السعر' : 'تم رفض السعر')
              : 'تعذّر تنفيذ الإجراء',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceProvider = context.watch<PriceProvider>();
    var entries = _filter == 'قيد المراجعة'
        ? priceProvider.entries.where((e) => e.status == 'pending').toList()
        : priceProvider.entries;
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

    return Column(
      children: [
        const _AdminGradientHeader(
          title: 'مراجعة الأسعار',
          subtitle: 'راجع وأدر الأسعار المقدمة من المستخدمين',
          icon: Icons.attach_money,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WaffirSearchField(hint: 'ابحث عن منتج، متجر أو مستخدم...'),
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
                options: const ['الكل', 'قيد المراجعة', 'مشهورة'],
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
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _review(e, false),
                                      icon: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      label: const Text(
                                        'رفض',
                                        style:
                                            TextStyle(color: AppColors.error),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColors.error,
                                        ),
                                        minimumSize: const Size(0, 38),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _review(e, true),
                                      icon: const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: const Text('موافقة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        minimumSize: const Size(0, 38),
                                      ),
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
// REPORTS SCREEN
// ✅ الآن يقرأ من ReportProvider، وكل صف قابل للنقر لتحديث حالة البلاغ
// عبر ReportProvider.updateStatus().
// ✅ جديد — فلتر الحي بجانب فلتر الكتلة الإدارية، يظهر فقط بعد اختيار كتلة.
// ══════════════════════════════════════════════════════════════════════════════
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _filter = 'الكل';
  // ✅ فلتر الكتلة الإدارية، يُشتق تصنيف كل بلاغ تلقائياً من حقل
  // r.storeArea (راجع ReportModel في models.dart) عبر AleppoBlocks.blockOfArea.
  String _blockFilter = 'الكل';
  // ✅ جديد — فلتر الحي، يظهر فقط بعد اختيار كتلة إدارية محددة، ويُعاد
  // ضبطه تلقائياً إلى "الكل" كلما تغيّرت الكتلة.
  String _areaFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'wrong_price':
        return 'سعر\nغير صحيح';
      case 'outdated':
        return 'سعر\nقديم';
      case 'duplicate':
        return 'تكرار';
      default:
        return 'أخرى';
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'wrong_price':
        return AppColors.error;
      case 'outdated':
        return AppColors.warning;
      case 'duplicate':
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _changeStatus(ReportModel r) async {
    final chosen = await showModalBottomSheet<String>(
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
                title: const Text('تمت المراجعة'),
                onTap: () => Navigator.pop(ctx, 'reviewed'),
              ),
              ListTile(
                title: const Text('تم الحل'),
                onTap: () => Navigator.pop(ctx, 'resolved'),
              ),
              ListTile(
                title: const Text('قيد الانتظار'),
                onTap: () => Navigator.pop(ctx, 'pending'),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<ReportProvider>().updateStatus(r.id, chosen);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم تحديث حالة البلاغ' : 'تعذّر التحديث'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final statusMap = {'قيد الانتظار': 'pending', 'تمت المراجعة': 'reviewed'};
    var reports = _filter == 'الكل'
        ? reportProvider.reports
        : reportProvider.reports
            .where((r) => r.status == statusMap[_filter])
            .toList();
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
          subtitle: 'راجع وأدر البلاغات المقدمة من المستخدمين',
          icon: Icons.flag_outlined,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WaffirSearchField(hint: 'ابحث عن منتج، متجر أو مستخدم...'),
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
                options: const ['الكل', 'قيد الانتظار', 'تمت المراجعة'],
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
                        return GestureDetector(
                          onTap: () => _changeStatus(r),
                          child: Container(
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
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      r.status == 'pending'
                                          ? 'قيد الانتظار'
                                          : r.status == 'reviewed'
                                              ? 'تمت المراجعة'
                                              : 'تم الحل',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: r.status == 'resolved'
                                            ? AppColors.success
                                            : AppColors.textSecondaryOf(
                                                context),
                                      ),
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
// ✅ الآن يقرأ من AdminUsersProvider، وكل صف قابل للنقر لفتح إجراءات فعلية
// (حظر/رفع حظر، ترقية إلى مدير) عبر AdminUsersProvider.
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
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    final provider = context.read<AdminUsersProvider>();
    final messenger = ScaffoldMessenger.of(context);
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
        const _AdminGradientHeader(
          title: 'إدارة المستخدمين',
          subtitle: 'إدارة حسابات المستخدمين والصلاحيات',
          icon: Icons.people_outlined,
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

  void _showAddProduct(BuildContext context) {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    String unit = 'كغ';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'إضافة منتج جديد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                        final ok =
                            await context.read<ProductProvider>().createProduct(
                                  name: nameCtrl.text.trim(),
                                  category: catCtrl.text.trim(),
                                  unit: unit,
                                );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'تمت إضافة المنتج' : 'تعذّر إضافة المنتج',
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
          onAction: () => _showAddProduct(context),
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
                      child: Row(
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            p.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${p.pricesCount}',
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
                          const SizedBox(width: 10),
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
        const _AdminGradientHeader(
          title: 'إدارة المتاجر',
          subtitle: 'راجع وتحقق من المتاجر المسجلة',
          icon: Icons.store_outlined,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.area,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${s.pricesCount}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 10),
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
                                ],
                              ),
                              const SizedBox(height: 6),
                              // ✅ شارة الكتلة الإدارية أسفل كل متجر
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
                                    block,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
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
  void _showAddLocation(BuildContext context) {
    final landmarkCtrl = TextEditingController();
    String selectedBlock = AleppoBlocks.all.first.name;
    String selectedArea = AleppoBlocks.all.first.areas.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'إضافة موقع جديد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                    child: Text('الحي', style: TextStyle(fontSize: 13)),
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
                        final ok =
                            await context.read<CatalogProvider>().addLocation(
                                  sector: selectedBlock,
                                  area: selectedArea,
                                  landmark: landmarkCtrl.text.trim(),
                                );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'تمت الإضافة' : 'تعذّرت الإضافة',
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
    final catalog = context.watch<CatalogProvider>();
    var locations = _blockFilter == 'الكل'
        ? catalog.locations
        : catalog.locations.where((l) => l.sector == _blockFilter).toList();
    // ✅ جديد — فلترة إضافية حسب الحي المحدد
    if (_areaFilter != 'الكل') {
      locations = locations.where((l) => l.area == _areaFilter).toList();
    }

    return Column(
      children: [
        _AdminGradientHeader(
          title: 'إدارة المواقع والكتل',
          subtitle: 'أدر الكتل الإدارية الخمس وأحياءها',
          icon: Icons.location_on_outlined,
          actionLabel: 'إضافة موقع',
          onAction: () => _showAddLocation(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WaffirSearchField(hint: 'ابحث عن حي أو معلم...'),
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
                          child: Row(
                            children: [
                              Text(
                                l.area,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  l.landmark,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${l.storesCount}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // ✅ شارة الكتلة الإدارية بدل نص "حلب" العام السابق
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l.sector,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
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
// UNITS SCREEN — ✅ من CatalogProvider، إضافة/حذف فعليان
// ══════════════════════════════════════════════════════════════════════════════
class AdminUnitsScreen extends StatefulWidget {
  const AdminUnitsScreen({super.key});
  @override
  State<AdminUnitsScreen> createState() => _AdminUnitsScreenState();
}

class _AdminUnitsScreenState extends State<AdminUnitsScreen> {
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
        const SizedBox(height: 4),
        Expanded(
          child: catalog.isLoading && catalog.units.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: catalog.units.length,
                  itemBuilder: (ctx, i) {
                    final u = catalog.units[i];
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
                                // ✅ لا يوجد endpoint موثّق لتعديل وحدة موجودة — نوضّح
                                // ذلك بدل ترك الزر بلا استجابة أو محاكاة نجاح كاذب.
                                onPressed: () => showComingSoonDialog(
                                  ctx,
                                  title: 'تعديل الوحدة',
                                  message:
                                      'تعديل اسم وحدة موجودة يتطلب endpoint إضافياً '
                                      '(PATCH /units/{id}) غير موجود بعد في التوثيق.',
                                ),
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
        const SizedBox(height: 4),
        Expanded(
          child: catalog.isLoading && catalog.brands.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: catalog.brands.length,
                  itemBuilder: (ctx, i) {
                    final b = catalog.brands[i];
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
                                onPressed: () => showComingSoonDialog(
                                  ctx,
                                  title: 'تعديل العلامة التجارية',
                                  message:
                                      'تعديل علامة تجارية موجودة يتطلب endpoint إضافياً '
                                      '(PATCH /brands/{id}) غير موجود بعد في التوثيق.',
                                ),
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
// ══════════════════════════════════════════════════════════════════════════════
class AdminOfficialPricesScreen extends StatefulWidget {
  const AdminOfficialPricesScreen({super.key});
  @override
  State<AdminOfficialPricesScreen> createState() =>
      _AdminOfficialPricesScreenState();
}

class _AdminOfficialPricesScreenState extends State<AdminOfficialPricesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadOfficialPrices();
    });
  }

  void _showAddOfficialPrice(BuildContext context) {
    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'كيلوغرام');
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'إضافة سعر رسمي جديد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: Text('المنتج', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: productCtrl,
                decoration: const InputDecoration(hintText: 'اسم المنتج'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الكمية', style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '1'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الوحدة', style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(
                            hintText: 'كيلوغرام',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('السعر (ل.س)', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '0'),
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
                      final qty = double.tryParse(qtyCtrl.text.trim());
                      final price = double.tryParse(priceCtrl.text.trim());
                      if (productCtrl.text.trim().isEmpty ||
                          qty == null ||
                          price == null) {
                        return;
                      }
                      final navigator = Navigator.of(ctx);
                      final ok = await context
                          .read<CatalogProvider>()
                          .addOfficialPrice(
                            productName: productCtrl.text.trim(),
                            unit: unitCtrl.text.trim(),
                            quantity: qty,
                            price: price,
                          );
                      navigator.pop();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? 'تمت الإضافة' : 'تعذّرت الإضافة'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('إضافة'),
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

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    return Column(
      children: [
        _AdminGradientHeader(
          title: 'الأسعار الرسمية',
          subtitle: 'أدر الأسعار الرسمية للمنتجات',
          icon: Icons.description_outlined,
          actionLabel: 'إضافة سعر رسمي',
          onAction: () => _showAddOfficialPrice(context),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: WaffirSearchField(hint: 'ابحث عن منتج...'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: catalog.isLoading && catalog.officialPrices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: catalog.officialPrices.length,
                  itemBuilder: (ctx, i) {
                    final op = catalog.officialPrices[i];
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
                          Text(
                            op.productName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
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
                          const SizedBox(width: 10),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: AppColors.primary,
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
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
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
              _AdminCard(
                child: _tappableRow(
                  onTap: () => showComingSoonDialog(
                    context,
                    title: 'سجل النشاط',
                    message:
                        'سجل النشاط يعرض كل الإجراءات التي قام بها المسؤولون، وهو '
                        'يعتمد بالكامل على بيانات الخادم، لذا سيظهر فور ربط التطبيق '
                        'بالـ backend.',
                  ),
                  label: 'سجل النشاط',
                  emoji: '📋',
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
                child: _tappableRow(
                  onTap: () => showComingSoonDialog(
                    context,
                    title: 'صلاحيات المسؤولين',
                    message:
                        'إدارة أدوار وصلاحيات المسؤولين المتعددين تتطلب نظام صلاحيات '
                        'على الخادم، وستكون متاحة بعد ربط التطبيق بالـ backend.',
                  ),
                  label: 'صلاحيات المسؤولين',
                  emoji: '⚙️',
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