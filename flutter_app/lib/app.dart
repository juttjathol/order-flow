import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/license/license_screen.dart';
import 'features/admin/admin_home.dart';
import 'features/order_taking/order_taker_home.dart';
import 'features/kitchen/kitchen_home.dart';
import 'features/cashier/cashier_home.dart';
import 'shared/theme/app_theme.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/license',
      builder: (context, state) => const LicenseScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHome(),
    ),
    GoRoute(
      path: '/order-taker',
      builder: (context, state) => const OrderTakerHome(),
    ),
    GoRoute(
      path: '/kitchen',
      builder: (context, state) => const KitchenHome(),
    ),
    GoRoute(
      path: '/cashier',
      builder: (context, state) => const CashierHome(),
    ),
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

/// First screen – choose role / join or start server
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Order Flow',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Local network order system',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _RoleButton(
                icon: Icons.dns,
                title: 'Start as Main Device',
                subtitle: 'This device becomes the server. Menu, inventory & settings live here.',
                onTap: () => context.go('/admin'),
              ),
              const SizedBox(height: 12),
              _RoleButton(
                icon: Icons.point_of_sale,
                title: 'Order Taker',
                subtitle: 'Take orders, assign table, send to kitchen.',
                onTap: () => context.go('/order-taker'),
              ),
              const SizedBox(height: 12),
              _RoleButton(
                icon: Icons.soup_kitchen,
                title: 'Kitchen Display',
                subtitle: 'See incoming orders and mark them ready.',
                onTap: () => context.go('/kitchen'),
              ),
              const SizedBox(height: 12),
              _RoleButton(
                icon: Icons.payments,
                title: 'Cashier / Reception',
                subtitle: 'Payments, invoices, close tables.',
                onTap: () => context.go('/cashier'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/license'),
                child: const Text('License / Activation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
