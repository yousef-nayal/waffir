import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/aleppo_blocks.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/models.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PRODUCTS SCREEN
// ✅ الآن تقرأ من ProductProvider (يتحول تلقائياً بين MockData والـ backend
// الحقيقي حسب AppConfig.useMockData) بدل قراءة MockData.products مباشرة.
// ══════════════════════════════════════════════════════════════════════════════
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _filter = 'الكل';
  final List<String> _cats = ['الكل', 'حبوب', 'زيوت', 'سكريات', 'بقوليات'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;
    final productProvider = context.watch<ProductProvider>();
    final allProducts = productProvider.products;
    final products = _filter == 'الكل'
        ? allProducts
        : allProducts.where((p) => p.category == _filter).toList();

    // ✅ إصلاح RTL: هذه الشاشة مسجّلة كمسار مستقل (AppRoutes.products) في
    // main.dart، بالإضافة لكونها أحد أطفال IndexedStack داخل UserShell.
    // التغليف الصريح هنا يضمن RTL في الحالتين، بدل الاعتماد فقط على
    // Directionality التي توفّرها UserShell عند الوصول عبر شريط التنقل.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            // ── رأس متدرّج أزرق — بنفس نمط الصفحة الرئيسية وشاشة المتاجر
            // ليكون التصميم متناسقاً في كل واجهات التطبيق ─────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ✅ عنوان "المنتجات" في المنتصف
                      const Text('المنتجات',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      // ✅ زر الثيم على اليمين (بدل أعلى يسار الشاشة سابقاً)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: provider.toggleDarkMode,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                                isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                color: Colors.white,
                                size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WaffirSearchField(
                hint: 'ابحث عن منتج...',
                onChanged: (v) =>
                    context.read<ProductProvider>().loadProducts(search: v),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilterChipRow(
                  options: _cats,
                  selected: _filter,
                  onSelected: (v) => setState(() => _filter = v)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: productProvider.isLoading && products.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? Center(
                          child: Text('لا توجد منتجات',
                              style: TextStyle(
                                  color: AppColors.textSecondaryOf(context))))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: products.length,
                          itemBuilder: (ctx, i) => _ProductCard(
                            product: products[i],
                            onTap: () => Navigator.pushNamed(
                                ctx, AppRoutes.productDetail,
                                arguments: products[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Row(
          children: [
            PriceChangeBadge(
                percent: product.changePercent, isUp: product.isPriceUp),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context))),
                    Text(product.category,
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    // ✅ عرض السعرين بوضوح: الحقيقي على اليمين بلون مميز، والرسمي
                    // على اليسار بلون مميز آخر بدل الخط المشطوب الباهت سابقاً.
                    Row(children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_f(product.realPrice)} ل.س/${product.unit}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const Text('حقيقي',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Container(
                          height: 24,
                          width: 1,
                          color: isDark ? Colors.white24 : AppColors.border),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_f(product.officialPrice)} ل.س',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning)),
                          const Text('رسمي',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning)),
                        ],
                      ),
                    ]),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  String _f(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(0)},000' : v.toStringAsFixed(0);
}

// ══════════════════════════════════════════════════════════════════════════════
// PRODUCT DETAIL SCREEN
// ✅ تحويل إلى StatefulWidget: تُحمَّل أسعار هذا المنتج تحديداً عبر
// PriceProvider.loadProductPrices(product.id) بدل عرض MockData.priceEntries
// (التي لم تكن حتى مرتبطة بالمنتج المعروض). كما أُضيف تصويت فعلي
// (إعجاب/عدم إعجاب) وزر بلاغ فعلي يفتحان الآن PriceProvider/ReportProvider
// بدل أن يكونا مجرّد نص بلا استجابة.
// ══════════════════════════════════════════════════════════════════════════════
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _product = ModalRoute.of(context)!.settings.arguments as ProductModel? ??
          MockData.products.first;
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PriceProvider>().loadProductPrices(_product!.id);
      });
    }
  }

  Future<void> _reportEntry(PriceEntry entry) async {
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: const Text('الإبلاغ عن هذا السعر'),
          children: const [
            _ReportTypeOption(value: 'wrong_price', label: 'سعر غير صحيح'),
            _ReportTypeOption(value: 'outdated', label: 'سعر قديم'),
            _ReportTypeOption(value: 'duplicate', label: 'تكرار'),
            _ReportTypeOption(value: 'other', label: 'أخرى'),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context
        .read<ReportProvider>()
        .submitReport(priceEntryId: entry.id, type: type);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(ok ? 'شكراً، تم إرسال بلاغك' : 'تعذّر إرسال البلاغ'),
        backgroundColor: ok ? AppColors.success : AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final product = _product!;
    final provider = context.watch<AppProvider>();
    final priceProvider = context.watch<PriceProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios,
                                      color: Colors.white, size: 18),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                IconButton(
                                    icon: Icon(
                                        provider.isDarkMode
                                            ? Icons.light_mode_outlined
                                            : Icons.dark_mode_outlined,
                                        color: Colors.white),
                                    onPressed: provider.toggleDarkMode),
                              ]),
                          const SizedBox(height: 8),
                          Text(product.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700)),
                          Text(product.category,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                                child: _PriceStat(
                                    label: 'السعر الرسمي',
                                    value:
                                        '${_f(product.officialPrice)}\nل.س/${product.unit}')),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _PriceStat(
                                    label: 'الوسيط',
                                    value:
                                        '${_f(product.avgPrice)}\nل.س/${product.unit}')),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _PriceStat(
                                    label: 'السعر الحقيقي',
                                    value:
                                        '${_f(product.realPrice)}\nل.س/${product.unit}',
                                    isHighlight: true)),
                          ]),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: product.isPriceUp
                                  ? AppColors.errorLight
                                  : AppColors.successLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  product.isPriceUp
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: product.isPriceUp
                                      ? AppColors.error
                                      : AppColors.success,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text(
                                  '${product.changePercent.toStringAsFixed(0)}%+ الفرق عن الرسمي',
                                  style: TextStyle(
                                      color: product.isPriceUp
                                          ? AppColors.error
                                          : AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ]),
                          ),
                        ]),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الأسعار المسجلة',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryOf(context))),
                        Text('${product.pricesCount} سعر',
                            style: TextStyle(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 13)),
                      ]),
                  const SizedBox(height: 12),
                  if (priceProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  // ✅ جديد — حالة خطأ صريحة بدل شاشة فارغة بلا تفسير عند
                  // فشل التحميل (سواء من الـ backend أو خطأ غير متوقع)
                  else if (priceProvider.state == LoadingState.error)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                size: 32, color: AppColors.error),
                            const SizedBox(height: 8),
                            Text(
                                priceProvider.errorMessage ??
                                    'تعذّر تحميل الأسعار',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textSecondaryOf(context))),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => context
                                  .read<PriceProvider>()
                                  .loadProductPrices(product.id),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (priceProvider.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: Text('لا توجد أسعار مسجّلة بعد',
                              style: TextStyle(
                                  color: AppColors.textSecondaryOf(context)))),
                    )
                  else
                    ..._safeBuildEntries(context, priceProvider.entries),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.addPrice,
                        arguments: product),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إضافة سعر لهذا المنتج'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _f(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)},${(v % 1000).toInt().toString().padLeft(3, '0')}'
      : v.toStringAsFixed(0);

  // ══════════════════════════════════════════════════════════════════════
  // ✅ جديد — شبكة أمان: بناء بطاقات الأسعار داخل try/catch صريح. سابقاً لو
  // حدث أي خطأ غير متوقع أثناء بناء إحدى البطاقات (بيانات ناقصة من الخادم
  // الحقيقي مستقبلاً، مثلاً)، كان بإمكان القسم كاملاً أن يختفي بصمت دون أي
  // رسالة — بالضبط الشكوى المُبلَّغ عنها ("الأسعار المسجلة لا تظهر"). الآن
  // أي خطأ من هذا النوع يُستبدَل برسالة واضحة وزر "إعادة المحاولة" بدل شاشة
  // فارغة غامضة. كل بطاقة تحمل أيضاً Key ثابتاً (entry.id) لتفادي أي تضارب
  // في إعادة بناء القائمة عند تحديث الأصوات.
  // ══════════════════════════════════════════════════════════════════════
  List<Widget> _safeBuildEntries(BuildContext context, List<PriceEntry> list) {
    try {
      return list
          .map((e) => _PriceEntryCard(
                key: ValueKey('price_entry_${e.id}'),
                entry: e,
                onThumbUp: () =>
                    context.read<PriceProvider>().vote(e.id, isUp: true),
                onThumbDown: () =>
                    context.read<PriceProvider>().vote(e.id, isUp: false),
                onReport: () => _reportEntry(e),
              ))
          .toList();
    } catch (err) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 32, color: AppColors.error),
                const SizedBox(height: 8),
                Text('تعذّر عرض الأسعار المسجّلة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondaryOf(context))),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<PriceProvider>()
                      .loadProductPrices(_product!.id),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
  }
}

class _ReportTypeOption extends StatelessWidget {
  final String value;
  final String label;
  const _ReportTypeOption({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () => Navigator.pop(context, value),
        child: Text(label),
      );
}

class _PriceStat extends StatelessWidget {
  final String label, value;
  final bool isHighlight;
  const _PriceStat(
      {required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isHighlight ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ✅ إصلاح Crash جوهري — "RenderFlex children have non-zero flex but incoming
// width constraints are unbounded" (السبب المباشر لتوقف تحميل "الأسعار
// المسجلة" على دوّامة تحميل بلا نهاية):
//
// الصف السفلي (تصويت + "منذ ... — بواسطة ...") كان يحوي Row ثانياً كطفل
// عادي (بلا Expanded/Flexible) داخل Row أب بترتيب spaceBetween. في Flutter،
// أي طفل غير مرن (non-flex) داخل Row يحصل تلقائياً على قيود عرض غير محدودة
// (unbounded) على المحور الرئيسي — وبما أن هذا الـ Row الداخلي يحوي بدوره
// عنصر Flexible (نص "بواسطة ...")، فإن التخطيط ينهار فور محاولة حساب
// المساحة المتبقية له، فتتوقف الشاشة عند مؤشر التحميل بصمت.
//
// الإصلاح: تغليف الـ Row الثاني بـ Expanded ليحصل على عرض محدود فعلي من
// الأب، مع الإبقاء على Flexible داخله لقصّ اسم المستخدم الطويل بدل تجاوز
// الحدود. كما أُضيف mainAxisSize.min لصفوف التصويت (لا حاجة فعلية لها
// بالتمدد) كإجراء وقائي إضافي.
// ══════════════════════════════════════════════════════════════════════════════
class _PriceEntryCard extends StatelessWidget {
  final PriceEntry entry;
  final VoidCallback onThumbUp;
  final VoidCallback onThumbDown;
  final VoidCallback onReport;
  const _PriceEntryCard({
    super.key,
    required this.entry,
    required this.onThumbUp,
    required this.onThumbDown,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimaryOf(context))),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Flexible(
                        child: Text(entry.storeArea,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 11)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.primary),
                    ]),
                  ]),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.store_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            // ✅ زر البلاغ أصبح فعلياً — يفتح اختيار نوع البلاغ ويرسله عبر
            // ReportProvider بدل أن يكون أيقونة ثابتة بلا استجابة.
            GestureDetector(
              onTap: onReport,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.flag_outlined,
                  size: 18, color: AppColors.textHintOf(context)),
            ),
          ]),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${entry.totalRatings} تقييم',
                style: TextStyle(
                    color: AppColors.textSecondaryOf(context), fontSize: 11)),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.borderOf(context)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_f(entry.price)} ل.س',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text('${entry.quantity.toStringAsFixed(0)} ${entry.unit}',
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 12)),
                    if (entry.brand.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(entry.brand,
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ✅ التصويت أصبح فعلياً (كان يعرض الأرقام فقط بلا onTap) — يستدعي
          // PriceProvider.vote() بتحديث متفائل فوري.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ mainAxisSize.min: هذا الصف لا يحتاج للتمدد، ويبقى بحجمه
              // الطبيعي بدل أخذ مساحة أكبر من اللازم كطفل غير مرن في Row أب.
              Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: onThumbUp,
                  behavior: HitTestBehavior.opaque,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.thumb_up_outlined,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('${entry.thumbsUp}',
                        style: const TextStyle(
                            color: AppColors.success, fontSize: 13)),
                  ]),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onThumbDown,
                  behavior: HitTestBehavior.opaque,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.thumb_down_outlined,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('${entry.thumbsDown}',
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ]),
                ),
              ]),
              // ✅ الإصلاح الجوهري: تغليف هذا الصف بـ Expanded ليحصل على عرض
              // محدود فعلي (bounded) من الـ Row الأب بدل القيد غير المحدود
              // الذي كان يتسبب بانهيار التخطيط بصمت عند وجود Flexible بداخله.
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(_timeAgo(entry.submittedAt),
                        style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 11)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('بواسطة ${entry.submittedBy}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
      );

  String _f(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)},${(v % 1000).toInt().toString().padLeft(3, '0')}'
      : v.toStringAsFixed(0);

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'أمس';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// USER SETTINGS SCREEN
// ✅ محدَّث — "تغيير الموقع" أصبح يفتح منتقي الكتل/الأحياء الرسمي الموحّد
// (showLocationPickerSheet من common_widgets.dart) بدل قائمة محلية مسطحة من
// 10 أسماء مناطق وهمية لم تكن مطابقة للتقسيم الإداري الرسمي. كما أصبح الصف
// يعرض الموقع الحالي (المنطقة والكتلة) كنص ثانوي بدل الاكتفاء بالأيقونة.
//
// ✅ إصلاح RTL (جديد): في كل صفوف هذه الشاشة كان ترتيب الأطفال معكوساً —
// عنصر القيمة/التحكم (نص ثانوي أو Switch) يظهر أولاً في أقصى اليمين،
// والتسمية+الأيقونة تظهر في أقصى اليسار. الآن كل صف يبدأ بالتسمية+الأيقونة
// (يمين) وينتهي بالقيمة/التحكم (يسار)، بنفس منطق رأس home_screen.dart.
// ══════════════════════════════════════════════════════════════════════════════
class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});
  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
        () => _notifications = prefs.getBool('user_notifications') ?? true);
  }

  Future<void> _setNotifications(bool v) async {
    setState(() => _notifications = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_notifications', v);
  }

  void _showLanguageInfo() {
    showComingSoonDialog(
      context,
      title: 'اللغة',
      message: 'العربية هي اللغة الوحيدة المتوفرة حالياً. دعم لغات إضافية '
          'مخطط له في إصدار قادم من التطبيق.',
      icon: Icons.language,
    );
  }

  void _showEditProfile(AppProvider provider) {
    final nameCtrl = TextEditingController(text: provider.userName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تعديل الملف الشخصي',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    if (nameCtrl.text.trim().isEmpty) return;
                    final ok = await provider.updateProfile(
                        name: nameCtrl.text.trim());
                    navigator.pop();
                    messenger.showSnackBar(SnackBar(
                        content: Text(ok
                            ? 'تم تحديث الملف الشخصي'
                            : 'تعذّر التحديث، حاول مجدداً'),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.error));
                  },
                  child: const Text('حفظ'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ محدَّث — يستخدم الآن منتقي الكتل/الأحياء الموحّد بدل قائمة محلية
  void _showLocationPicker(AppProvider provider) {
    showLocationPickerSheet(
      context,
      currentBlock: provider.userBlock,
      currentArea: provider.userLocation,
      onSelect: (block, area) =>
          provider.updateLocation(block: block, area: area),
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
      await Navigator.pushNamed(context, AppRoutes.resetPassword,
          arguments: {'phone': provider.userPhone, 'fromSettings': true});
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(
              provider.errorMessage ?? 'تعذّر إرسال رمز التحقق، حاول مجدداً'),
          backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.white60 : AppColors.textSecondary;
    final sectionColor = isDark ? Colors.white38 : AppColors.textSecondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('التفضيلات', color: sectionColor),
            _SettingCard(
              isDark: isDark,
              onTap: _showLanguageInfo,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ التسمية + الأيقونة أولاً → تظهر يمين
                    Row(children: [
                      Text('اللغة',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(width: 8),
                      const Text('🌍', style: TextStyle(fontSize: 18)),
                    ]),
                    // ✅ القيمة الحالية أخيراً → تظهر يسار
                    Text('العربية',
                        style: TextStyle(color: textSecondary, fontSize: 14)),
                  ]),
            ),
            _SettingCard(
              isDark: isDark,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ التسمية + الأيقونة أولاً → تظهر يمين
                    Row(children: [
                      Text('الإشعارات',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(width: 8),
                      const Text('🔔', style: TextStyle(fontSize: 18)),
                    ]),
                    // ✅ مفتاح التبديل أخيراً → يظهر يسار
                    Switch(
                        value: _notifications,
                        onChanged: _setNotifications,
                        activeThumbColor: AppColors.primary),
                  ]),
            ),

            _SectionHeader('الخصوصية والأمان', color: sectionColor),
            _SettingCard(
              isDark: isDark,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text('الخصوصية',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(width: 8),
                      const Text('🔒', style: TextStyle(fontSize: 18)),
                    ]),
                    Icon(Icons.arrow_back_ios,
                        size: 14,
                        color: isDark ? Colors.white30 : AppColors.textHint),
                  ]),
            ),
            _SettingCard(
              isDark: isDark,
              onTap: () => _startChangePassword(provider),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text('تغيير كلمة المرور',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(width: 8),
                      const Text('🔐', style: TextStyle(fontSize: 18)),
                    ]),
                    Icon(Icons.arrow_back_ios,
                        size: 14,
                        color: isDark ? Colors.white30 : AppColors.textHint),
                  ]),
            ),

            _SectionHeader('الحساب', color: sectionColor),
            _SettingCard(
              isDark: isDark,
              onTap: () => _showEditProfile(provider),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text('تعديل الملف الشخصي',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(width: 8),
                      const Icon(Icons.person_outline,
                          size: 18, color: AppColors.primary),
                    ]),
                    Icon(Icons.arrow_back_ios,
                        size: 14,
                        color: isDark ? Colors.white30 : AppColors.textHint),
                  ]),
            ),
            // ✅ الصف يعرض الآن المنطقة الحالية كقيمة ثانوية في أقصى اليسار،
            // والتسمية+الأيقونة في أقصى اليمين، ويفتح منتقي الكتل/الأحياء
            // الرسمي عند النقر.
            _SettingCard(
              isDark: isDark,
              onTap: () => _showLocationPicker(provider),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text('تغيير الموقع',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: AppColors.primary),
                    ]),
                    Text(provider.userLocation,
                        style: TextStyle(color: textSecondary, fontSize: 14)),
                  ]),
            ),

            const SizedBox(height: 16),
            Center(
                child: Text('إصدار التطبيق\n1.0.0',
                    style: TextStyle(
                        color: isDark ? Colors.white38 : AppColors.textHint,
                        fontSize: 12),
                    textAlign: TextAlign.center)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final Color? color;
  const _SectionHeader(this.text, {this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text,
            style: TextStyle(
                color: color ?? AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final VoidCallback? onTap;
  const _SettingCard({required this.child, this.isDark = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.border)),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD PRICE SCREEN
// ✅ إصلاح جوهري: كانت الحقول تحمل الأسماء فقط (بلا IDs) وزر الإرسال كان
// Future.delayed وهمي حتى في وضع الإنتاج. الآن تُحمَّل قوائم المنتجات
// والمتاجر الحقيقية عبر ProductProvider/StoreProvider، ويحتفظ الاختيار
// بالـ id الفعلي، والإرسال يمرّ فعلياً عبر PriceProvider.submitPrice.
// ══════════════════════════════════════════════════════════════════════════════
class AddPriceScreen extends StatefulWidget {
  const AddPriceScreen({super.key});
  @override
  State<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends State<AddPriceScreen> {
  // ✅ جديد — لا قيمة اختيارية بعد الآن لعلامة تجارية: المستخدم يجب أن يختار
  // إما علامة حقيقية أو هذا الخيار الصريح "بدون علامة تجارية"، بدل ترك الحقل
  // فارغاً بصمت كما كان سابقاً.
  static const String _noBrandOption = 'بدون علامة تجارية';

  // ✅ جديد — الكتلة الإدارية يجب اختيارها أولاً قبل إتاحة اختيار المحل،
  // وقائمة المحلات المعروضة تُفلتَر تلقائياً لتشمل فقط محلات تلك الكتلة
  // (عبر AleppoBlocks.blockOfArea المطبَّق على حقل area الموجود أصلاً في
  // StoreModel — بلا حاجة لأي تعديل على الـ backend أو الـ model).
  String? _selectedBlock;
  String? _selectedProductId;
  String? _selectedStoreId;
  final _priceCtrl = TextEditingController(text: '15000');
  final _qtyCtrl = TextEditingController(text: '1');
  String _unit = 'كغ';
  // ✅ قيمة افتراضية بدل null — الحقل أصبح إجبارياً بالكامل
  String? _brand = _noBrandOption;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      final storeProvider = context.read<StoreProvider>();
      if (productProvider.products.isEmpty) productProvider.loadProducts();
      if (storeProvider.stores.isEmpty) storeProvider.loadStores();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ProductModel) {
        setState(() => _selectedProductId = args.id);
      }
    });
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // ✅ عند تغيير الكتلة يُعاد ضبط المحل المختار تلقائياً، لمنع بقاء محل من
  // كتلة سابقة لا ينتمي إلى الكتلة المختارة حديثاً.
  void _onBlockChanged(String? block) {
    if (block == null || block == _selectedBlock) return;
    setState(() {
      _selectedBlock = block;
      _selectedStoreId = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedBlock == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى اختيار الكتلة الإدارية'),
          backgroundColor: AppColors.error));
      return;
    }
    if (_selectedProductId == null || _selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى اختيار المنتج والمحل'),
          backgroundColor: AppColors.error));
      return;
    }
    if (_brand == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى اختيار العلامة التجارية'),
          backgroundColor: AppColors.error));
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (price == null || price <= 0 || qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى إدخال سعر وكمية صحيحين'),
          backgroundColor: AppColors.error));
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    final ok = await context.read<PriceProvider>().submitPrice(
          productId: _selectedProductId!,
          storeId: _selectedStoreId!,
          price: price,
          unit: _unit,
          quantity: qty,
          // ✅ "بدون علامة تجارية" هو خيار عرض فقط — لا يُرسَل للـ backend
          // كنص، بل يُترجَم إلى عدم إرسال حقل brand أصلاً (راجع
          // PriceEntry.toJson: `if (brand.isNotEmpty) 'brand': brand`).
          brand: _brand == _noBrandOption ? null : _brand,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('تم إرسال السعر بنجاح!'),
        backgroundColor: AppColors.success,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(
            context.read<PriceProvider>().errorMessage ?? 'تعذّر إرسال السعر'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final allStores = context.watch<StoreProvider>().stores;
    // ✅ محلات الكتلة المختارة فقط — فارغة حتى تُختار كتلة أولاً
    final storesInBlock = _selectedBlock == null
        ? const <StoreModel>[]
        : allStores
            .where(
                (s) => AleppoBlocks.blockOfArea(s.area)?.name == _selectedBlock)
            .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة سعر'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('ساعد الآخرين بمعرفة الأسعار الحقيقية',
                style: TextStyle(
                    color: AppColors.textSecondaryOf(context), fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _lbl(context, 'المنتج'),
            const SizedBox(height: 8),
            _IdDropdown(
              hint: 'اختر المنتج',
              value: _selectedProductId,
              items: {for (final p in products) p.id: p.name},
              onChanged: (v) => setState(() => _selectedProductId = v),
            ),
            const SizedBox(height: 16),
            // ✅ جديد — الكتلة الإدارية أولاً: تحدد قائمة المحلات المتاحة
            // أدناه، ولا يمكن اختيار محل قبل اختيار كتلة.
            _lbl(context, 'الكتلة الإدارية'),
            const SizedBox(height: 8),
            _Dropdown(
              hint: 'اختر الكتلة الإدارية',
              value: _selectedBlock,
              items: AleppoBlocks.blockNames,
              onChanged: _onBlockChanged,
            ),
            const SizedBox(height: 16),
            _lbl(context, 'المحل'),
            const SizedBox(height: 8),
            _selectedBlock == null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Row(children: [
                      Icon(Icons.lock_outline,
                          size: 18, color: AppColors.textHintOf(context)),
                      const SizedBox(width: 8),
                      Text('اختر الكتلة الإدارية أولاً',
                          style: TextStyle(
                              color: AppColors.textHintOf(context),
                              fontSize: 14)),
                    ]),
                  )
                : storesInBlock.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.borderOf(context)),
                        ),
                        child: Text('لا توجد محلات مسجّلة في هذه الكتلة',
                            style: TextStyle(
                                color: AppColors.textHintOf(context),
                                fontSize: 14)),
                      )
                    : _IdDropdown(
                        hint: 'اختر المحل',
                        value: _selectedStoreId,
                        items: {for (final s in storesInBlock) s.id: s.name},
                        onChanged: (v) => setState(() => _selectedStoreId = v),
                      ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    _lbl(context, 'الكمية'),
                    const SizedBox(height: 8),
                    TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1')),
                  ])),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    _lbl(context, 'الوحدة'),
                    const SizedBox(height: 8),
                    _Dropdown(
                        hint: 'الوحدة',
                        value: _unit,
                        items: const ['كغ', 'غرام', 'لتر', 'قطعة', 'علبة'],
                        onChanged: (v) => setState(() => _unit = v!)),
                  ])),
            ]),
            const SizedBox(height: 16),
            _lbl(context, 'السعر (ل.س)'),
            const SizedBox(height: 8),
            TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '15000')),
            const SizedBox(height: 16),
            _lbl(context, 'العلامة التجارية'),
            const SizedBox(height: 8),
            _Dropdown(
                hint: 'اختر العلامة التجارية',
                value: _brand,
                items: [
                  _noBrandOption,
                  ...MockData.brands.map((b) => b.name),
                ],
                onChanged: (v) => setState(() => _brand = v)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                    child: Text('تأكد من دقة المعلومات قبل الإرسال',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.primary))),
              ]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('إرسال السعر'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _lbl(BuildContext context, String t) => Text(t,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryOf(context)));
}

class _Dropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown(
      {required this.hint,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value,
        hint: Text(hint,
            style:
                TextStyle(color: AppColors.textHintOf(context), fontSize: 14)),
        isExpanded: true,
        style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14),
        dropdownColor: AppColors.surfaceOf(context),
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderOf(context))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderOf(context))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true,
          fillColor: AppColors.surfaceOf(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                value: item, child: Text(item, textAlign: TextAlign.right)))
            .toList(),
        onChanged: onChanged,
      );
}

/// ✅ جديد — نفس شكل [_Dropdown] لكن يحتفظ بمفتاح (id) مستقل عن التسمية
/// المعروضة، حتى يمكن إرسال product_id/store_id الحقيقيين إلى الـ backend
/// بدل الاسم النصي فقط.
class _IdDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final Map<String, String> items; // id -> label
  final ValueChanged<String?> onChanged;

  const _IdDropdown(
      {required this.hint,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: items.containsKey(value) ? value : null,
        hint: Text(hint,
            style:
                TextStyle(color: AppColors.textHintOf(context), fontSize: 14)),
        isExpanded: true,
        style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14),
        dropdownColor: AppColors.surfaceOf(context),
        decoration: InputDecoration(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderOf(context))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderOf(context))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true,
          fillColor: AppColors.surfaceOf(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(
                value: e.key, child: Text(e.value, textAlign: TextAlign.right)))
            .toList(),
        onChanged: onChanged,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// OFFICIAL PRICES SCREEN
// ✅ من CatalogProvider.officialPrices بدل MockData مباشرة.
// ✅ إصلاح RTL: اسم المادة (الكلام) أصبح أول عنصر في كل بطاقة → يظهر في
// أقصى اليمين، والسعر+التاريخ (التفاصيل) أصبحا في عمود ثانٍ يظهر في أقصى
// اليسار، مع سهم صغير يوضّح أن البطاقة قابلة للنقر — بدل الترتيب المعكوس
// سابقاً (التفاصيل يمين، الاسم يسار).
// ✅ جديد — كل بطاقة أصبحت قابلة للنقر وتفتح OfficialPriceHistoryScreen
// (سجل تغييرات هذه المادة عبر الزمن) عبر AppRoutes.officialPriceHistory.
// ══════════════════════════════════════════════════════════════════════════════
class OfficialPricesScreen extends StatefulWidget {
  const OfficialPricesScreen({super.key});

  @override
  State<OfficialPricesScreen> createState() => _OfficialPricesScreenState();
}

class _OfficialPricesScreenState extends State<OfficialPricesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadOfficialPrices();
    });
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtPrice(double v) => v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)},${(v % 1000).toInt().toString().padLeft(3, '0')}'
      : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final catalog = context.watch<CatalogProvider>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                      provider.isDarkMode
                                          ? Icons.light_mode_outlined
                                          : Icons.dark_mode_outlined,
                                      color: Colors.white),
                                  onPressed: provider.toggleDarkMode,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios,
                                      color: Colors.white, size: 18),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ]),
                          const SizedBox(height: 8),
                          const Text('الأسعار الرسمية',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('أسعار وزارة التموين',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13)),
                        ]),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.description_outlined,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'هذه الأسعار صادرة عن وزارة التموين والتجارة الداخلية',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.primary))),
                    ]),
                  ),
                  if (catalog.isLoading && catalog.officialPrices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...catalog.officialPrices.map((op) => GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.officialPriceHistory,
                              arguments: op),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: AppColors.surfaceOf(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.borderOf(context))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ✅ الكلام (اسم المادة + الكمية) أولاً →
                                // يظهر في أقصى اليمين، ويأخذ المساحة الأكبر
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(op.productName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppColors.textPrimaryOf(
                                                  context))),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.scale_outlined,
                                              size: 13,
                                              color: AppColors.textHintOf(
                                                  context)),
                                          const SizedBox(width: 4),
                                          Text(
                                              '${op.quantity.toStringAsFixed(0)} ${op.unit}',
                                              style: TextStyle(
                                                  color:
                                                      AppColors.textSecondaryOf(
                                                          context),
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // ✅ التفاصيل (السعر والتاريخ) أخيراً →
                                // تظهر في أقصى اليسار
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '${_fmtPrice(op.price)} ل.س/${op.unit}',
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_fmt(op.updatedAt),
                                            style: TextStyle(
                                                fontSize: 10.5,
                                                color:
                                                    AppColors.textSecondaryOf(
                                                        context))),
                                        const SizedBox(width: 4),
                                        Icon(Icons.calendar_today_outlined,
                                            size: 11,
                                            color:
                                                AppColors.textHintOf(context)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_back_ios,
                                    size: 13,
                                    color: AppColors.textHintOf(context)),
                              ],
                            ),
                          ),
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}