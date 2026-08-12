import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/models.dart';
import '../../core/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class AdminHome extends ConsumerStatefulWidget {
  const AdminHome({super.key});
  @override
  ConsumerState<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends ConsumerState<AdminHome> {
  bool _starting = false;

  Future<void> _toggle() async {
    final app = ref.read(appControllerProvider);
    setState(() => _starting = true);
    try {
      if (app.serverRunning) await app.stopMain();
      else await app.startAsMain();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server error: $e')));
    }
    if (mounted) setState(() => _starting = false);
  }

  void _menuEditor() {
    final app = ref.read(appControllerProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Column(children: [
            const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Expanded(child: ListView(children: app.menuItems.map((m) => ListTile(
              title: Text(m.name),
              subtitle: Text('\$${m.price.asDouble.toStringAsFixed(2)}'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { app.deleteMenuItem(m.id); Navigator.pop(ctx); }),
            )).toList())),
            FilledButton.icon(
              onPressed: () {
                final name = TextEditingController();
                final price = TextEditingController(text: '10.00');
                showDialog(context: context, builder: (dCtx) => AlertDialog(
                  title: const Text('Add item'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                    TextField(controller: price, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                  ]),
                  actions: [
                    FilledButton(onPressed: () {
                      final catId = app.categories.isNotEmpty ? app.categories.first.id : 'general';
                      if (app.categories.isEmpty) app.upsertCategory(MenuCategory(id: catId, name: 'General'));
                      final cents = ((double.tryParse(price.text) ?? 0) * 100).round();
                      app.upsertMenuItem(MenuItem(categoryId: catId, name: name.text.trim(), price: Money(cents)));
                      Navigator.pop(dCtx); Navigator.pop(ctx);
                    }, child: const Text('Add')),
                  ],
                ));
              },
              icon: const Icon(Icons.add),
              label: const Text('Add menu item'),
            ),
          ]),
        );
      },
    );
  }

  void _inventory() {
    final app = ref.read(appControllerProvider);
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.7,
      builder: (_, sc) => ListView.builder(controller: sc, itemCount: app.inventory.length, itemBuilder: (_, i) {
        final inv = app.inventory[i];
        return ListTile(
          title: Text(inv.name),
          subtitle: Text('Stock: ${inv.quantity.toStringAsFixed(0)}'),
          trailing: inv.quantity <= inv.lowStockThreshold ? const Text('LOW', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)) : null,
          onTap: () {
            final c = TextEditingController(text: inv.quantity.toStringAsFixed(0));
            showDialog(context: context, builder: (d) => AlertDialog(
              title: Text(inv.name),
              content: TextField(controller: c, keyboardType: TextInputType.number),
              actions: [FilledButton(onPressed: () { app.setInventoryQty(inv.id, double.tryParse(c.text) ?? inv.quantity); Navigator.pop(d); Navigator.pop(ctx); }, child: const Text('Save'))],
            ));
          },
        );
      }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Main Device'), actions: [
        Padding(padding: const EdgeInsets.only(right: 8), child: FilledButton.tonalIcon(
          onPressed: _starting ? null : _toggle,
          icon: Icon(app.serverRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
          label: Text(_starting ? '...' : (app.serverRunning ? 'Stop' : 'Start')),
        )),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: app.serverRunning ? const [Color(0xFF0EA5E9), Color(0xFF14B8A6)] : const [Color(0xFF64748B), Color(0xFF475569)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Row(children: [PulseDot(color: Colors.white, size: 12), const SizedBox(width: 10), Text(app.serverRunning ? 'Server running' : 'Server offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))]),
            const SizedBox(height: 12),
            Text(app.joinUrl, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w600)),
            const Text('PC: open this URL for local dashboard', style: TextStyle(color: Colors.white70, fontSize: 12)),
            if (app.serverRunning) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: 'orderflow://join?host=${app.localIp}&port=${app.port}', size: 140, backgroundColor: Colors.white)),
            ],
            TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: app.joinUrl)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'))); }, icon: const Icon(Icons.copy, color: Colors.white, size: 18), label: const Text('Copy', style: TextStyle(color: Colors.white))),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: StatCard(label: 'Open orders', value: '${app.openOrders.length}', icon: Icons.receipt_long, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Devices', value: '${app.devices.length}', icon: Icons.devices, color: AppColors.accent)),
        ]),
        const SizedBox(height: 12),
        StatCard(label: "Today's sales", value: '\$${app.todaySales.toStringAsFixed(2)}', icon: Icons.trending_up, color: AppColors.success),
        const SizedBox(height: 16),
        Card(child: ListTile(leading: const Icon(Icons.restaurant_menu, color: AppColors.primary), title: const Text('Menu'), onTap: _menuEditor)),
        Card(child: ListTile(leading: const Icon(Icons.inventory_2, color: AppColors.primary), title: const Text('Inventory'), onTap: _inventory)),
        Card(child: ListTile(leading: const Icon(Icons.receipt_long, color: AppColors.primary), title: Text('Orders (${app.orders.length})'), onTap: () {
          showModalBottomSheet(context: context, builder: (_) => ListView(children: app.orders.reversed.map((o) => ListTile(title: Text('#${o.orderNumber} · ${o.tableNumber ?? '—'}'), subtitle: Text('${o.status.name} · \$${o.total.asDouble.toStringAsFixed(2)}'))).toList()));
        })),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.home), label: const Text('Back to roles')),
      ]),
    );
  }
}
