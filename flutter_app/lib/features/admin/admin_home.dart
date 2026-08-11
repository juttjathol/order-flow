import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String localIp = '192.168.1.10';
  bool serverRunning = false;
  int port = 8787;

  void _toggleServer() {
    setState(() => serverRunning = !serverRunning);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(serverRunning ? 'Server started · other devices can join' : 'Server stopped'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final joinUrl = 'http://$localIp:$port';

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dns_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Main Device'),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: _toggleServer,
              icon: Icon(serverRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
              label: Text(serverRunning ? 'Stop' : 'Start'),
              style: FilledButton.styleFrom(
                backgroundColor: serverRunning ? AppColors.danger.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                foregroundColor: serverRunning ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          FadeSlideIn(
            index: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: serverRunning
                      ? const [Color(0xFF0EA5E9), Color(0xFF14B8A6)]
                      : isDark ? const [Color(0xFF334155), Color(0xFF1E293B)] : const [Color(0xFF94A3B8), Color(0xFF64748B)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: (serverRunning ? AppColors.primary : Colors.black).withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                Row(children: [
                  PulseDot(color: serverRunning ? Colors.white : Colors.white54, size: 12),
                  const SizedBox(width: 10),
                  Text(serverRunning ? 'Server running' : 'Server offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  if (serverRunning)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('Port $port', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ]),
                const SizedBox(height: 16),
                Text(joinUrl, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Open this URL on a PC browser for the full web dashboard',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(data: 'orderflow://join?host=$localIp&port=$port', size: 140, backgroundColor: Colors.white),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: joinUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied'), behavior: SnackBarBehavior.floating));
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                  label: const Text('Copy address', style: TextStyle(color: Colors.white)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(index: 1, child: Row(children: [
            Expanded(child: StatCard(label: 'Open orders', value: '0', icon: Icons.receipt_long_rounded, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: StatCard(label: 'Devices', value: '1', icon: Icons.devices_rounded, color: AppColors.accent)),
          ])),
          const SizedBox(height: 12),
          FadeSlideIn(index: 2, child: StatCard(label: "Today's sales", value: '0.00', icon: Icons.trending_up_rounded, color: AppColors.success)),
          const SizedBox(height: 24),
          Text('Manage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          ...[
            (Icons.restaurant_menu_rounded, [Color(0xFF0EA5E9), Color(0xFF0284C7)], 'Menu Management', 'Categories, items, prices'),
            (Icons.inventory_2_rounded, [Color(0xFF14B8A6), Color(0xFF0D9488)], 'Inventory', 'Stock · auto-deduct on orders'),
            (Icons.devices_rounded, [Color(0xFF8B5CF6), Color(0xFF7C3AED)], 'Connected Devices', 'Phones and tablets online'),
            (Icons.receipt_long_rounded, [Color(0xFFF59E0B), Color(0xFFD97706)], 'Orders and Reports', 'Sales, invoices, history'),
            (Icons.print_rounded, [Color(0xFF64748B), Color(0xFF475569)], 'Printers', 'Kitchen and cashier network printers'),
            (Icons.settings_rounded, [Color(0xFFEC4899), Color(0xFFDB2777)], 'Settings', 'Tax, currency, restaurant name'),
          ].asMap().entries.map((e) {
            final item = e.value;
            return FadeSlideIn(
              index: 3 + e.key,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ScaleTap(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.$3} — coming next'), behavior: SnackBarBehavior.floating)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      GradientIconBox(icon: item.$1, colors: item.$2, size: 44),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.$3, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(item.$4, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ])),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ]),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.home_rounded), label: const Text('Back to roles')),
        ],
      ),
    );
  }
}
