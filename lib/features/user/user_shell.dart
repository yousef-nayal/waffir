import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_routes.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/stores_screen.dart';
import 'screens/profile_screen.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  // Nav indices: 0=Home, 1=Products, 2=FAB(unused), 3=Stores, 4=Profile
  int _currentIndex = 0;

  // Maps _currentIndex → IndexedStack child index (0-3)
  // This MUST stay in sync with the children list below
  int get _stackIndex {
    switch (_currentIndex) {
      case 1:
        return 1; // ProductsScreen
      case 3:
        return 2; // StoresScreen
      case 4:
        return 3; // ProfileScreen
      default:
        return 0; // HomeScreen (covers 0 and 2/FAB)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // IndexedStack keeps all screens alive (no rebuild on tab switch)
        // Children order MUST match _stackIndex mapping above
        body: IndexedStack(
          index: _stackIndex,
          children: const [
            HomeScreen(),     // stackIndex 0
            ProductsScreen(), // stackIndex 1
            StoresScreen(),   // stackIndex 2
            ProfileScreen(),  // stackIndex 3
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.addPrice),
          backgroundColor: AppColors.primary,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 8,
          color: Theme.of(context).colorScheme.surface,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              // ══════════════════════════════════════════════════════════
              // ✅ إصلاح RTL جوهري: في Row داخل سياق RTL، أول عنصر في القائمة
              // يُرسم في أقصى اليمين، وآخر عنصر يُرسم في أقصى اليسار. الترتيب
              // السابق كان [الملف، المتاجر، فراغ الزر العائم، المنتجات،
              // الرئيسية]، ما ينتج عنه فعلياً: "الملف الشخصي" في أقصى اليمين
              // و"الرئيسية" في أقصى اليسار — أي معكوس تماماً عن الترتيب
              // الطبيعي المتوقع في تطبيق عربي (الرئيسية أولاً من اليمين).
              // الترتيب الجديد يعطي، من اليمين إلى اليسار:
              //   الرئيسية → المنتجات → (الزر العائم) → المتاجر → الملف الشخصي
              // ══════════════════════════════════════════════════════════
              children: [
                _NavItem(
                    icon: Icons.home_outlined,
                    label: 'الرئيسية',
                    index: 0,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(
                    icon: Icons.shopping_basket_outlined,
                    label: 'المنتجات',
                    index: 1,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                const SizedBox(width: 48), // FAB space
                _NavItem(
                    icon: Icons.store_outlined,
                    label: 'المتاجر',
                    index: 3,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(
                    icon: Icons.person_outline,
                    label: 'الملف الشخصي',
                    index: 4,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = current == index;
    final color = isSelected ? AppColors.primary : AppColors.textHint;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? _filledIcon(icon) : icon,
                color: color, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  IconData _filledIcon(IconData icon) {
    if (icon == Icons.home_outlined) return Icons.home;
    if (icon == Icons.shopping_basket_outlined) return Icons.shopping_basket;
    if (icon == Icons.store_outlined) return Icons.store;
    if (icon == Icons.person_outline) return Icons.person;
    return icon;
  }
}
