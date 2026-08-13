import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/l10n/app_strings.dart';
import 'core/state/app_controller.dart';
import 'features/license/license_screen.dart';
import 'features/admin/admin_home.dart';
import 'features/order_taking/order_taker_home.dart';
import 'features/kitchen/kitchen_home.dart';
import 'features/cashier/cashier_home.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/animated_widgets.dart';

final _router = GoRouter(
  initialLocation: '/license',
  routes: [
    GoRoute(path: '/license', builder: (_, __) => const LicenseScreen()),
    GoRoute(path: '/', builder: (_, __) => const RoleSelectScreen()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminHome()),
    GoRoute(path: '/order-taker', builder: (_, __) => const OrderTakerHome()),
    GoRoute(path: '/kitchen', builder: (_, __) => const KitchenHome()),
    GoRoute(path: '/cashier', builder: (_, __) => const CashierHome()),
  ],
);

class OrderFlowApp extends ConsumerWidget {
  const OrderFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appControllerProvider.select((a) => a.localeCode));
    final s = S(locale);
    return MaterialApp.router(
      title: 'Order Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      builder: (context, child) {
        return Directionality(
          textDirection: s.direction,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final s = S(app.localeCode);

    if (!app.hasLicense) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/license');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.appName,
                          style: s.isUrdu
                              ? GoogleFonts.notoNastaliqUrdu(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.7,
                                  color: const Color(0xFF0F172A))
                              : const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A))),
                      Text(s.chooseRole,
                          style: s.isUrdu
                              ? GoogleFonts.notoNastaliqUrdu(
                                  color: AppColors.muted, fontSize: 15, height: 1.6)
                              : TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => app.setLocale(app.localeCode == 'ur' ? 'en' : 'ur'),
                  child: Text(
                    app.localeCode == 'ur' ? 'EN' : 'اردو',
                    style: app.localeCode == 'en'
                        ? GoogleFonts.notoNastaliqUrdu(fontWeight: FontWeight.w700)
                        : const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              index: 0,
              child: _RoleCard(
                icon: Icons.dns_rounded,
                title: s.mainDevice,
                subtitle: s.isUrdu ? 'سرور، مینو، انوینٹری' : 'Server · menu · inventory',
                color: AppColors.primary,
                onTap: () => context.go('/admin'),
              ),
            ),
            FadeSlideIn(
              index: 1,
              child: _RoleCard(
                icon: Icons.room_service_rounded,
                title: s.orderTaker,
                subtitle: s.isUrdu ? 'ٹیبل آرڈر لیں' : 'Take table orders',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.go('/order-taker'),
              ),
            ),
            FadeSlideIn(
              index: 2,
              child: _RoleCard(
                icon: Icons.soup_kitchen_rounded,
                title: s.kitchen,
                subtitle: s.isUrdu ? 'کچن کیو' : 'Kitchen queue',
                color: AppColors.warning,
                onTap: () => context.go('/kitchen'),
              ),
            ),
            FadeSlideIn(
              index: 3,
              child: _RoleCard(
                icon: Icons.point_of_sale_rounded,
                title: s.cashier,
                subtitle: s.isUrdu ? 'بل اور ادائیگی' : 'Bills & payment',
                color: AppColors.success,
                onTap: () => context.go('/cashier'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.go('/license'),
              icon: const Icon(Icons.vpn_key_rounded, size: 18),
              label: Text(s.license),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
