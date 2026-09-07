import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/app_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/aleppo_blocks.dart';
import '../../../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════
// عناصر مشتركة لكل شاشات المصادقة (تصميم موحّد واحترافي)
// ══════════════════════════════════════════════════════════════════════════

/// الرأس المتدرّج الأزرق المشترك بين كل شاشات تسجيل الدخول/الإنشاء،
/// بنفس هوية شاشة السبلاش والشاشة الرئيسية.
class _AuthHeader extends StatelessWidget {
  final Widget icon;
  final List<Color> gradientColors;
  final double height;

  const _AuthHeader({
    required this.icon,
    this.gradientColors = const [Color(0xFF1D4ED8), Color(0xFF2563EB)],
    this.height = 225,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: icon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ إصلاح وضوح الشعار: كانت الأيقونة تجلس بالضبط على الخط الفاصل بين
// التدرّج الأزرق والبطاقة البيضاء (بسبب Matrix4.translationValues(0,-28,0)
// في _AuthCard سابقاً)، فيختلط نصفها العلوي بالخلفية الزرقاء ونصفها السفلي
// بالبطاقة البيضاء، ما يجعلها تبدو باهتة/غير واضحة. الحل: إطار أبيض
// سميك (halo) حول الأيقونة بالكامل + ظل أقوى وأعمق يفصلها بوضوح تام
// عن أي خلفية خلفها، مع تكبير حجمها قليلاً — بالإضافة إلى تقليل ارتفاع
// تراكب البطاقة إلى -4 (بدل -28) وزيادة ارتفاع الرأس المتدرّج وهامش
// الشعار السفلي، ليحصل الشعار على مساحة أكبر بوضوح تام فوق البطاقة.
Widget _iconAvatar(IconData icon, {Color bg = Colors.white}) => Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 38),
    );

/// بطاقة بيضاء منحنية الحواف العلوية تحمل محتوى الفورم — بنفس أسلوب
/// الشاشة الرئيسية والملف الشخصي (رأس ملون + بطاقة بيضاء متداخلة).
/// ✅ إصلاح: كانت البطاقة ترتفع فتغطي جزءاً من شعار الرأس (icon avatar)
/// فيبدو مقصوصاً/غير واضح خلفها. تم تقليل التراكب أكثر (-4 فقط) مع زيادة
/// ارتفاع الرأس المتدرّج، ليحصل الشعار على مساحة أوضح وأكبر فوق البطاقة.
class _AuthCard extends StatelessWidget {
  final Widget child;
  const _AuthCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: child,
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context,
    {required String label, required IconData icon, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    suffixIcon: suffix,
  );
}

Widget _primaryButton({
  required String label,
  required bool loading,
  required VoidCallback? onPressed,
  Color? color,
}) {
  return SizedBox(
    height: 54,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: (color != null
              ? ElevatedButton.styleFrom(
                  backgroundColor: color,
                  elevation: 2,
                  shadowColor: color.withValues(alpha: 0.5))
              : ElevatedButton.styleFrom(
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5)))
          .copyWith(
        // ✅ إصلاح: كانت حشوة الزر الافتراضية ضيقة جداً مع بعض التسميات
        // الطويلة (مثل "دخول لوحة الإدارة")، ما قد يقصّ جزءاً من النص.
        // حشوة أفقية صريحة + FittedBox أدناه يضمنان ظهور النص كاملاً دوماً.
        padding:
            WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20)),
      ),
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.4),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
    ),
  );
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// LOGIN
// ══════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<AppProvider>();
    setState(() => _isLoading = true);
    final success = await provider.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.userHome, (_) => false);
    } else {
      _showError(
          context, provider.errorMessage ?? 'تعذّر تسجيل الدخول، حاول مجدداً');
    }
  }

  // ✅ استُبدلت النافذة المنبثقة (bottom sheet) بشاشة كاملة احترافية
  // (ForgotPasswordScreen) ضمن password_recovery_screens.dart، تتضمن دورة
  // كاملة: طلب رمز → إدخال الرمز + كلمة مرور جديدة.
  void _showForgotPassword() {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _AuthHeader(icon: _iconAvatar(Icons.storefront_rounded)),
              _AuthCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ✅ عنوان أكبر وأثقل وزناً لضمان وضوحه بالكامل
                      Text('مرحباً بك 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryOf(context))),
                      const SizedBox(height: 6),
                      Text('سجل دخولك لمتابعة الأسعار',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: _fieldDecoration(context,
                            label: 'رقم الهاتف', icon: Icons.phone_outlined),
                        validator: (v) => (v == null || v.trim().length < 8)
                            ? 'أدخل رقم هاتف صحيح'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: _fieldDecoration(context,
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: AppColors.textHintOf(context)),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            )),
                        validator: (v) => (v == null || v.length < 4)
                            ? 'كلمة المرور قصيرة جداً'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _primaryButton(
                          label: 'دخول',
                          loading: _isLoading,
                          onPressed: _submit),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ليس لديك حساب؟ ',
                              style: TextStyle(
                                  color: AppColors.textSecondaryOf(context))),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.register),
                            child: const Text('إنشاء حساب جديد',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// REGISTER
// ✅ إصلاح جوهري: اختيار "المنطقة" كان قائمة مسطحة واحدة من 12 حياً وهمياً
// لا تطابق التقسيم الإداري الرسمي لحلب (الكتل الخمس). الآن حقلان متتاليان:
//   1) "الكتلة الإدارية" — إحدى الكتل الخمس الرسمية (aleppo_blocks.dart)
//   2) "الحي" — يُبنى تلقائياً حسب الكتلة المختارة فقط (cascading dropdown)،
//      ويُعاد ضبطه تلقائياً كلما تغيّرت الكتلة لمنع اختيار حي لا ينتمي إليها.
// ══════════════════════════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  // ✅ الكتلة الإدارية المختارة، والحي التابع لها (يُعاد بناؤه ديناميكياً)
  late String _selectedBlock = AleppoBlocks.all.first.name;
  late String _selectedArea = AleppoBlocks.all.first.areas.first;

  void _onBlockChanged(String? block) {
    if (block == null || block == _selectedBlock) return;
    setState(() {
      _selectedBlock = block;
      // ✅ إعادة ضبط المنطقة تلقائياً على أول منطقة في الكتلة الجديدة، لمنع بقاء
      // منطقة من الكتلة السابقة لا تنتمي إلى الكتلة المختارة حديثاً.
      _selectedArea = AleppoBlocks.areasOfBlock(block).first;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<AppProvider>();
    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final success = await provider.register(
      name: _nameController.text.trim(),
      phone: phone,
      password: _passwordController.text,
      block: _selectedBlock,
      area: _selectedArea,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      // ✅ بعد إنشاء الحساب مباشرة: تأكيد رقم الهاتف برمز التفعيل (OTP)
      // بدل الدخول المباشر للتطبيق.
      Navigator.pushReplacementNamed(context, AppRoutes.otpVerification,
          arguments: phone);
    } else {
      _showError(
          context, provider.errorMessage ?? 'تعذّر إنشاء الحساب، حاول مجدداً');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ الأحياء المتاحة تُشتق دوماً من الكتلة المختارة حالياً
    final areasOfSelectedBlock = AleppoBlocks.areasOfBlock(_selectedBlock);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _AuthHeader(
                  icon: _iconAvatar(Icons.person_add_alt_1_rounded),
                  height: 198),
              _AuthCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('إنشاء حساب جديد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryOf(context))),
                      const SizedBox(height: 6),
                      Text('انضم إلى وفّر وتابع الأسعار',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: _fieldDecoration(context,
                            label: 'الاسم الكامل', icon: Icons.person_outline),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'أدخل اسمك الكامل'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: _fieldDecoration(context,
                            label: 'رقم الهاتف', icon: Icons.phone_outlined),
                        validator: (v) => (v == null || v.trim().length < 8)
                            ? 'أدخل رقم هاتف صحيح'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // ✅ 1) الكتلة الإدارية
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBlock,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimaryOf(context),
                          height: 1.3,
                        ),
                        decoration: _fieldDecoration(context,
                            label: 'الكتلة', icon: Icons.map_outlined),
                        items: AleppoBlocks.blockNames
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b,
                                      style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: _onBlockChanged,
                      ),
                      const SizedBox(height: 14),
                      // ✅ 2) المنطقة — قائمته تتغيّر تلقائياً حسب الكتلة أعلاه.
                      // مفتاح فريد يتضمن الكتلة المختارة يجبر Flutter على
                      // إعادة بناء الحقل عند تغيّر الكتلة بدل الاحتفاظ بحالة
                      // داخلية قديمة لا تتوافق مع القائمة الجديدة.
                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedBlock),
                        initialValue:
                            areasOfSelectedBlock.contains(_selectedArea)
                                ? _selectedArea
                                : areasOfSelectedBlock.first,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimaryOf(context),
                          height: 1.3,
                        ),
                        decoration: _fieldDecoration(context,
                            label: 'المنطقة', icon: Icons.location_on_outlined),
                        items: areasOfSelectedBlock
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a,
                                      style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedArea = v ?? _selectedArea),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: _fieldDecoration(context,
                            label: 'كلمة المرور',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: AppColors.textHintOf(context)),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            )),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        decoration: _fieldDecoration(context,
                            label: 'تأكيد كلمة المرور',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: AppColors.textHintOf(context)),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            )),
                        validator: (v) => v != _passwordController.text
                            ? 'كلمتا المرور غير متطابقتين'
                            : null,
                      ),
                      const SizedBox(height: 22),
                      _primaryButton(
                          label: 'إنشاء حساب',
                          loading: _isLoading,
                          onPressed: _submit),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('لديك حساب بالفعل؟ ',
                              style: TextStyle(
                                  color: AppColors.textSecondaryOf(context))),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('تسجيل الدخول',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ADMIN LOGIN
// ✅ جديد — أُضيف زر "نسيت كلمة المرور؟" أسفل حقل كلمة المرور، محاذى لأقصى
// اليمين (طبيعي في واجهة عربية RTL)، يفتح نفس دورة الاستعادة الموجودة أصلاً
// (ForgotPasswordScreen → ResetPasswordScreen) لكن مع تمرير isAdmin: true
// حتى تُعيد الدورة المستخدم إلى شاشة دخول الإدارة بعد النجاح، بدل شاشة
// تسجيل الدخول العادية.
// ══════════════════════════════════════════════════════════════════════════
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<AppProvider>();
    setState(() => _isLoading = true);
    final success = await provider.adminLogin(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.adminDashboard, (_) => false);
    } else {
      _showError(context, provider.errorMessage ?? 'بيانات الدخول غير صحيحة');
    }
  }

  // ✅ جديد — يفتح دورة استعادة كلمة المرور نفسها المستخدمة في تسجيل دخول
  // المستخدم العادي، مع تمرير isAdmin: true لتمييز الوجهة النهائية بعد النجاح.
  void _showForgotPassword() {
    Navigator.pushNamed(
      context,
      AppRoutes.forgotPassword,
      arguments: const {'isAdmin': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _AuthHeader(
                // ✅ إطار أبيض + ظل أقوى ليتضح الشعار تماماً فوق الخلفية
                // الداكنة جداً لهذه الشاشة
                icon: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 36),
                ),
                gradientColors: const [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                height: 212,
              ),
              Container(
                width: double.infinity,
                // ✅ لا يوجد أي تراكب مع الرأس الآن (بلا transform سلبي)، حتى لا
                // يُقطع شعار الدرع خلف بطاقة تسجيل دخول الإدارة الداكنة أبداً،
                // مع رأس أطول قليلاً يمنح الشعار مساحة أوضح وأكبر فوق البطاقة.
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ✅ عنوان أثقل وزناً وأكبر قليلاً لوضوح تام على الخلفية الداكنة
                      const Text('لوحة الإدارة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      const Text('تسجيل دخول المسؤولين',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFFB9C6DE),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: _darkFieldDecoration(
                            label: 'رقم الهاتف', icon: Icons.phone_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'هذا الحقل مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: _darkFieldDecoration(
                          label: 'كلمة المرور',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: Colors.white38),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'أدخل كلمة المرور'
                            : null,
                      ),
                      // ✅ جديد — نسيت كلمة المرور، محاذى لأقصى اليمين
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'نسيت كلمة المرور؟',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: AppColors.primaryLight, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'هذه الصفحة مخصصة للمسؤولين فقط. الدخول غير المصرح به ممنوع.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue.shade100),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _primaryButton(
                        label: 'دخول لوحة الإدارة',
                        loading: _isLoading,
                        onPressed: _submit,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _darkFieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
    );
  }
}
