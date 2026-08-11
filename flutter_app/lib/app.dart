import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/license/license_screen.dart';
import 'features/admin/admin_home.dart';
import 'features/order_taking/order_taker_home.dart';
import 'features/kitchen/kitchen_home.dart';
import 'features/cashier/cashier_home.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/animated_widgets.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const RoleSelectScreen()),
    GoRoute(path: '/license', builder: (_, __) => const LicenseScreen()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminHome()),
    GoRoute(path: '/order-taker', builder: (_, __) => const OrderTakerHome()),
    GoRoute(path: '/kitchen', builder: (_, __) => const KitchenHome()),
    GoRoute(path: '/cashier', builder: (_, __) => const CashierHome()),
  ],
);

class OrderFlowApp extends StatelessWidget {
  const OrderFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Order Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)]
                : const [Color(0xFFF0F9FF), Color(0xFFF8FAFC), Color(0xFFECFEFF)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SpiverHeader(),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeSlideIn(index: 3, child: _RoleCard(icon: Icons.dns_rounded, colors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)], title: 'Main Device', subtitle: 'PC or tablet as the server. Menu, inventory, reports and local web dashboard.', badge: 'RECOMMENDED', onTap: () => context.go('/admin'))),
                    const SizedBox(height: 12),
                    FadeSlideIn(index: 4, child: _RoleCard(icon: Icons.point_of_sale_rounded, colors: const [Color(0xFF14B8A6), Color(0xFF0D9488)], title: 'Order Taker', subtitle: 'Wait staff · take orders, assign table, send to kitchen.', onTap: () => context.go('/order-taker'))),
                    const SizedBox(height: 12),
                    FadeSlideIn(index: 5, child: _RoleCard(icon: Icons.soup_kitchen_rounded, colors: const [Color(0xFFF59E0B), Color(0xFFD97706)], title: 'Kitchen Display', subtitle: 'Live tickets · mark preparing and ready · print support.', onTap: () => context.go('/kitchen'))),
                    const SizedBox(height: 12),
                    FadeSlideIn(index: 6, child: _RoleCard(icon: Icons.payments_rounded, colors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)], title: 'Cashier / Reception', subtitle: 'Close bills, print receipts, manage payments.', onTap: () => context.go('/cashier'))),
                    const SizedBox(height: 28),
                    FadeSlideIn(index: 7, child: Center(child: TextButton.icon(onPressed: () => context.go('/license'), icon: const Icon(Icons.vpn_key_rounded, size: 18), label: const Text('License / Activation')))),
                    const SizedBox(height: 16),
                    FadeSlideIn(index: 8, child: Text('All devices share orders in real time on your local network', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpiverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
        child: Column(
          children: [
            FadeSlideIn(index: 0, child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 36),
            )),
            const SizedBox(height: 20),
            FadeSlideIn(index: 1, child: Text('Order Flow', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8))),
            const SizedBox(height: 6),
            FadeSlideIn(index: 2, child: Text('Professional order system · works offline on your network', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4))),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _RoleCard({required this.icon, required this.colors, required this.title, required this.subtitle, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            GradientIconBox(icon: icon, colors: colors),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2))),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: colors.first.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(badge!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: colors.first, letterSpacing: 0.4)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.35)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
