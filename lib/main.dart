import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/utils/app_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/auth_screens.dart' as auth;
import 'features/auth/presentation/screens/password_recovery_screens.dart'
    as recovery;
import 'features/user/user_shell.dart';
import 'features/user/screens/products_screen.dart';
import 'features/user/screens/stores_screen.dart';
import 'features/user/screens/profile_screen.dart';
// ✅ جديد
import 'features/user/screens/official_price_history_screen.dart';
import 'features/admin/admin_shell.dart';
import 'features/legal/legal_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => AdminUsersProvider()),
      ],
      child: const WaffirApp(),
    ),
  );
}

class WaffirApp extends StatelessWidget {
  const WaffirApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'وفّر',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const auth.LoginScreen(),
        AppRoutes.register: (_) => const auth.RegisterScreen(),
        AppRoutes.adminLogin: (_) => const auth.AdminLoginScreen(),
        AppRoutes.userHome: (_) => const UserShell(),
        AppRoutes.adminDashboard: (_) => const AdminShell(),
        AppRoutes.products: (_) => const ProductsScreen(),
        AppRoutes.productDetail: (_) => ProductDetailScreen(),
        AppRoutes.stores: (_) => const StoresScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.userSettings: (_) => const UserSettingsScreen(),
        AppRoutes.addPrice: (_) => const AddPriceScreen(),
        AppRoutes.officialPrices: (_) => const OfficialPricesScreen(),
        // ✅ جديد — سجل تغييرات مادة واحدة من الأسعار الرسمية
        AppRoutes.officialPriceHistory: (_) =>
            const OfficialPriceHistoryScreen(),
        AppRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),
        AppRoutes.termsOfService: (_) => const TermsOfServiceScreen(),
        AppRoutes.forgotPassword: (_) => const recovery.ForgotPasswordScreen(),
        AppRoutes.otpVerification: (_) =>
            const recovery.OtpVerificationScreen(),
        AppRoutes.resetPassword: (_) => const recovery.ResetPasswordScreen(),
      },
    );
  }
}