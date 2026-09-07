import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/mock_data.dart';
import '../../../core/utils/app_provider.dart';
import '../../../core/constants/aleppo_blocks.dart';
import '../../../core/constants/app_routes.dart';
import '../../../models/models.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  // ✅ إصلاح شامل: كانت التصفية مسطحة بقائمة مناطق وهمية (7 عناصر) لا تطابق
  // التقسيم الإداري الرسمي. الآن مستويان: الكتلة الإدارية أولاً (5 كتل +
  // "الكل")، ثم أحياء الكتلة المختارة كصف ثانٍ من الفلاتر يظهر فقط عند
  // اختيار كتلة محدّدة. كل متجر يُصنَّف تلقائياً ضمن كتلته عبر
  // AleppoBlocks.blockOfArea بالاعتماد على حقل area الموجود أصلاً في
  // StoreModel (بلا حاجة لتعديل الـ model أو الـ backend).
  String _blockFilter = 'الكل';
  String _areaFilter = 'الكل';
  String _search = '';

  List<String> get _areasOfSelectedBlock {
    if (_blockFilter == 'الكل') return const [];
    return AleppoBlocks.areasOfBlock(_blockFilter);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;
    final textPrimary = AppColors.textPrimaryOf(context);
    final textHint = AppColors.textHintOf(context);
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);

    final stores = MockData.stores.where((s) {
      final storeBlock = AleppoBlocks.blockOfArea(s.area)?.name;
      final matchesBlock = _blockFilter == 'الكل' || storeBlock == _blockFilter;
      final matchesArea = _areaFilter == 'الكل' || s.area == _areaFilter;
      final matchesSearch = _search.isEmpty ||
          s.name.contains(_search) ||
          s.area.contains(_search);
      return matchesBlock && matchesArea && matchesSearch;
    }).toList();

    // ✅ إصلاح RTL: هذه الشاشة مسجّلة كمسار مستقل (AppRoutes.stores) في
    // main.dart، بالإضافة لكونها أحد أطفال IndexedStack داخل UserShell.
    // التغليف الصريح هنا يضمن RTL في الحالتين، بدل الاعتماد فقط على
    // Directionality التي توفّرها UserShell عند الوصول عبر شريط التنقل.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            // ── رأس متدرّج أزرق — بنفس نمط الصفحة الرئيسية وشاشة المنتجات
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
                      // ✅ عنوان "المتاجر" في المنتصف تماماً
                      const Text('المتاجر',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      // ✅ زر الثيم على اليسار بشكل موحد في جميع الواجهات
                      Align(
                        alignment: Alignment.centerLeft,
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
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'ابحث عن متجر...',
                  hintStyle: TextStyle(color: textHint),
                  prefixIcon: Icon(Icons.search, color: textHint),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2)),
                  filled: true,
                  fillColor: surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // ── صف فلترة الكتلة الإدارية ────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AleppoBlocks.all.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final label = i == 0 ? 'الكل' : AleppoBlocks.all[i - 1].name;
                  final selected = _blockFilter == label;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _blockFilter = label;
                      _areaFilter =
                          'الكل'; // ✅ إعادة ضبط فلتر الحي عند تغيير الكتلة
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? AppColors.primary : border),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondaryOf(context),
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  );
                },
              ),
            ),
            // ── صف فلترة الحي — يظهر فقط بعد اختيار كتلة محدّدة ─────────
            if (_blockFilter != 'الكل') ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _areasOfSelectedBlock.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final label =
                        i == 0 ? 'الكل' : _areasOfSelectedBlock[i - 1];
                    final selected = _areaFilter == label;
                    return GestureDetector(
                      onTap: () => setState(() => _areaFilter = label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: selected ? AppColors.primary : border,
                              width: 1),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondaryOf(context),
                                fontSize: 11.5,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: stores.isEmpty
                  ? Center(
                      child: Text('لا توجد متاجر',
                          style: TextStyle(
                              color: AppColors.textSecondaryOf(context))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stores.length,
                      itemBuilder: (ctx, i) => _StoreCard(store: stores[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final StoreModel store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final isDark = AppColors.isDark(context);
    // ✅ الكتلة تُشتق من المنطقة تلقائياً لعرضها في تفاصيل المتجر
    final block = AleppoBlocks.blockOfArea(store.area)?.name ?? store.sector;

    return GestureDetector(
      onTap: () => _showStoreDetail(context, store, block),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (store.isVerified)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('موثق',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      Text(store.name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(store.address,
                      style: TextStyle(color: textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('${store.pricesCount} سعر',
                          style: TextStyle(color: textSecondary, fontSize: 11)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(store.area,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.store_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            // Arrow
            Icon(Icons.arrow_back_ios,
                size: 14, color: AppColors.textHintOf(context)),
          ],
        ),
      ),
    );
  }

  void _showStoreDetail(BuildContext context, StoreModel store, String block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.borderOf(ctx),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.store,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryOf(ctx))),
                        Text(block,
                            style: TextStyle(
                                color: AppColors.textSecondaryOf(ctx))),
                      ],
                    ),
                  ),
                  if (store.isVerified)
                    const Icon(Icons.verified,
                        color: AppColors.success, size: 24),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'العنوان',
                  value: store.address),
              _DetailRow(
                  icon: Icons.map_outlined, label: 'الحي', value: store.area),
              _DetailRow(
                  icon: Icons.location_city,
                  label: 'الكتلة الإدارية',
                  value: block),
              _DetailRow(
                  icon: Icons.attach_money,
                  label: 'عدد الأسعار',
                  value: '${store.pricesCount} سعر مسجل'),
              const SizedBox(height: 20),
              // ✅ إصلاح جوهري: كان الزر يكتفي بإغلاق الـ bottom sheet
              // (Navigator.pop(ctx)) بلا أي تنقّل فعلي، فبدا وكأنه "لا يعمل".
              // الآن يُغلق الـ sheet أولاً، ثم يفتح AddPriceScreen عبر
              // AppRoutes.addPrice مع تمرير هذا المتجر (StoreModel) كوسيط.
              // AddPriceScreen (راجع products_screen.dart) أصبحت تتعرّف على
              // StoreModel في الوسائط وتملأ تلقائياً: الكتلة الإدارية
              // (مُشتقّة من store.area عبر AleppoBlocks.blockOfArea) وتختار
              // هذا المتجر تحديداً في قائمة "المحل"، بدل تركهما فارغين
              // ليختارهما المستخدم يدوياً من جديد.
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx); // إغلاق الـ bottom sheet أولاً
                  Navigator.pushNamed(context, AppRoutes.addPrice,
                      arguments: store);
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة سعر لهذا المتجر'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textPrimaryOf(context)),
                  textAlign: TextAlign.right),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: AppColors.textSecondaryOf(context), fontSize: 13)),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: AppColors.primary),
          ],
        ),
      );
}