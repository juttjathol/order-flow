import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/models.dart';
import '../../core/services/print_service.dart';
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
  int _tab = 0;

  Future<void> _toggle() async {
    final app = ref.read(appControllerProvider);
    setState(() => _starting = true);
    try {
      if (app.serverRunning) await app.stopMain();
      else await app.startAsMain();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server: $e')));
    }
    if (mounted) setState(() => _starting = false);
  }

  String _sym(AppController a) => a.bill.currencySymbol;

  void _settings() {
    final app = ref.read(appControllerProvider);
    final name = TextEditingController(text: app.bill.restaurantName);
    final addr = TextEditingController(text: app.bill.address);
    final phone = TextEditingController(text: app.bill.phone);
    final tax = TextEditingController(text: app.bill.taxId);
    final footer = TextEditingController(text: app.bill.footer);
    final cur = TextEditingController(text: app.bill.currencySymbol);
    final kitchen = TextEditingController(text: app.kitchenPrinterIp ?? '');
    final cashier = TextEditingController(text: app.cashierPrinterIp ?? '');
    var model = app.businessModel;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: ListView(shrinkWrap: true, children: [
            const Text('Business & bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final m in ['restaurant', 'retail', 'fastfood', 'services'])
                ChoiceChip(
                  label: Text(m),
                  selected: model == m,
                  onSelected: (_) => setLocal(() => model = m),
                ),
            ]),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Business name')),
            TextField(controller: addr, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: tax, decoration: const InputDecoration(labelText: 'Tax ID')),
            TextField(controller: footer, decoration: const InputDecoration(labelText: 'Footer')),
            TextField(controller: cur, decoration: const InputDecoration(labelText: 'Currency')),
            Wrap(spacing: 6, children: [r'$$', '€', '£', 'Rs', 'RM', 'AED', '₹'].map((s) {
              final sym = s == r'$$' ? r'$' : s;
              return ActionChip(label: Text(sym), onPressed: () => setLocal(() => cur.text = sym));
            }).toList()),
            TextField(controller: kitchen, decoration: const InputDecoration(labelText: 'Kitchen printer IP')),
            TextField(controller: cashier, decoration: const InputDecoration(labelText: 'Cashier printer IP')),
            FilledButton(onPressed: () async {
              await app.setBusinessModel(model);
              await app.saveSettings(
                billProfile: BillProfile(
                  restaurantName: name.text.trim().isEmpty ? 'My Business' : name.text.trim(),
                  address: addr.text.trim(),
                  phone: phone.text.trim(),
                  taxId: tax.text.trim(),
                  footer: footer.text.trim().isEmpty ? 'Thank you!' : footer.text.trim(),
                  currencySymbol: cur.text.trim().isEmpty ? r'$' : cur.text.trim(),
                ),
                kitchenIp: kitchen.text.trim(),
                cashierIp: cashier.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: const Text('Save')),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final sym = _sym(app);
    final titles = ['Home', 'Tables', 'Menu', 'Stock', 'More'];

    Widget dash = ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: app.serverRunning ? const [Color(0xFF14532D), Color(0xFF22C55E)] : const [Color(0xFF3F3F46), Color(0xFF52525B)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const PulseDot(color: Colors.white, size: 10),
            const SizedBox(width: 10),
            Expanded(child: Text(app.serverRunning ? 'Main server online' : 'Server offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF14532D)),
              onPressed: _starting ? null : _toggle,
              child: Text(_starting ? '...' : (app.serverRunning ? 'Stop' : 'Start')),
            ),
          ]),
          if (app.serverRunning && app.localIp != null) ...[
            const SizedBox(height: 10),
            Text('${app.localIp}:${app.port}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16)),
            Text(app.joinUrl, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: app.joinUrl, size: 100, backgroundColor: Colors.white),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: StatCard(label: 'Open', value: '${app.openOrders.length}', icon: Icons.receipt_long, color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Today', value: '$sym${app.todaySales.toStringAsFixed(0)}', icon: Icons.trending_up, color: AppColors.success)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: StatCard(label: 'Orders', value: '${app.todayOrderCount}', icon: Icons.shopping_bag, color: AppColors.info)),
        const SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Low stock', value: '${app.lowStockItems.length}', icon: Icons.warning_amber, color: AppColors.warning)),
      ]),
      const SizedBox(height: 14),
      const Text('Open orders', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 8),
      if (app.openOrders.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No open orders', style: TextStyle(color: AppColors.muted)))),
      ...app.openOrders.take(10).map((o) => Card(
        color: AppColors.card,
        child: ListTile(
          title: Text('Table ${o.tableNumber ?? '—'} · #${o.orderNumber}', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
          subtitle: Text('${o.status.name} · $sym${o.total.asDouble.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.muted)),
        ),
      )),
      const SizedBox(height: 80),
    ]);

    final occupied = <String, Order>{};
    for (final o in app.openOrders) {
      final t = (o.tableNumber ?? '').trim();
      if (t.isNotEmpty) occupied[t] = o;
    }
    final nums = <String>{...List.generate(12, (i) => '${i + 1}'), ...occupied.keys}.toList()..sort();
    Widget tables = Column(children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Align(alignment: Alignment.centerLeft, child: Text('Table map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text))),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 4 : 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: nums.length,
          itemBuilder: (_, i) {
            final n = nums[i];
            final o = occupied[n];
            final bg = o == null ? AppColors.tableEmpty : (o.status == OrderStatus.ready ? AppColors.tableWaiting : AppColors.tableOrdered);
            return Container(
              decoration: BoxDecoration(
                color: bg.withValues(alpha: o == null ? 0.35 : 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bg),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.table_restaurant, color: o == null ? AppColors.muted : Colors.white),
                Text(n, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: o == null ? AppColors.muted : Colors.white)),
                Text(o == null ? 'Free' : '$sym${o.total.asDouble.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: o == null ? AppColors.muted : Colors.white70)),
              ]),
            );
          },
        ),
      ),
    ]);

    Widget menu = Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              final name = TextEditingController();
              final price = TextEditingController(text: '10');
              showDialog(context: context, builder: (d) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Add item'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: price, decoration: InputDecoration(labelText: 'Price ($sym)'), keyboardType: TextInputType.number),
                ]),
                actions: [FilledButton(onPressed: () {
                  if (name.text.trim().isEmpty) return;
                  final catId = app.categories.isNotEmpty ? app.categories.first.id : 'general';
                  if (app.categories.isEmpty) app.upsertCategory(MenuCategory(id: catId, name: 'General'));
                  app.upsertMenuItem(MenuItem(categoryId: catId, name: name.text.trim(), price: Money(((double.tryParse(price.text) ?? 0) * 100).round())));
                  Navigator.pop(d);
                }, child: const Text('Add'))],
              ));
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ]),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: app.menuItems.length,
          itemBuilder: (_, i) {
            final m = app.menuItems[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Expanded(child: Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text))),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), onPressed: () => app.deleteMenuItem(m.id)),
                ]),
                Text('$sym${m.price.asDouble.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
              ]),
            );
          },
        ),
      ),
    ]);

    Widget stock = Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          const Text('Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const Spacer(),
          if (app.lowStockItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('${app.lowStockItems.length} low', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              final name = TextEditingController();
              final qty = TextEditingController(text: '0');
              final unit = TextEditingController(text: 'pcs');
              showDialog(context: context, builder: (d) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Add inventory'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: qty, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number),
                  TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')),
                ]),
                actions: [FilledButton(onPressed: () {
                  if (name.text.trim().isEmpty) return;
                  app.addInventoryItem(name: name.text.trim(), quantity: double.tryParse(qty.text) ?? 0, unit: unit.text.trim().isEmpty ? 'pcs' : unit.text.trim());
                  Navigator.pop(d);
                }, child: const Text('Add'))],
              ));
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ]),
      ),
      Expanded(
        child: app.inventory.isEmpty
            ? const Center(child: Text('No inventory', style: TextStyle(color: AppColors.muted)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: app.inventory.length,
                itemBuilder: (_, i) {
                  final inv = app.inventory[i];
                  final low = inv.quantity <= inv.lowStockThreshold;
                  return Card(
                    color: AppColors.card,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: low ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (low ? AppColors.warning : AppColors.primary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory_2_outlined, color: low ? AppColors.warning : AppColors.primary),
                      ),
                      title: Text(inv.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        'Stock: ${inv.quantity.toStringAsFixed(0)} ${inv.unit}${low ? ' · LOW' : ''}',
                        style: TextStyle(color: low ? AppColors.warning : AppColors.muted, fontWeight: low ? FontWeight.w700 : FontWeight.w400),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.muted, size: 20),
                          onPressed: () {
                            final c = TextEditingController(text: inv.quantity.toStringAsFixed(0));
                            showDialog(context: context, builder: (d) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: Text(inv.name),
                              content: TextField(controller: c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Qty (${inv.unit})')),
                              actions: [FilledButton(onPressed: () {
                                app.setInventoryQty(inv.id, double.tryParse(c.text) ?? inv.quantity);
                                Navigator.pop(d);
                              }, child: const Text('Save'))],
                            ));
                          },
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), onPressed: () => app.deleteInventoryItem(inv.id)),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);

    Widget more = ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
      const Text('More', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 12),
      Card(color: AppColors.card, child: ListTile(leading: const Icon(Icons.settings, color: AppColors.primary), title: const Text('Business · bill · printers', style: TextStyle(color: AppColors.text)), trailing: const Icon(Icons.chevron_right, color: AppColors.muted), onTap: _settings)),
      Card(color: AppColors.card, child: ListTile(leading: const Icon(Icons.delivery_dining, color: AppColors.primary), title: const Text('Drivers', style: TextStyle(color: AppColors.text)), onTap: () {
        final name = TextEditingController();
        final phone = TextEditingController();
        showDialog(context: context, builder: (d) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add driver'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
          ]),
          actions: [FilledButton(onPressed: () {
            if (name.text.trim().isEmpty) return;
            app.drivers = [...app.drivers, {'id': DateTime.now().millisecondsSinceEpoch.toString(), 'name': name.text.trim(), 'phone': phone.text.trim(), 'status': 'free'}];
            app.notifyListeners();
            Navigator.pop(d);
          }, child: const Text('Add'))],
        ));
      })),
      Card(color: AppColors.card, child: ListTile(leading: const Icon(Icons.bar_chart, color: AppColors.primary), title: const Text('Today report', style: TextStyle(color: AppColors.text)), onTap: () {
        final r = app.salesReport(days: 1);
        showDialog(context: context, builder: (d) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Today'),
          content: Text('Orders: ${r['orders']}\nSales: $sym${(r['total'] as double).toStringAsFixed(2)}\nLow stock: ${r['lowStock']}', style: const TextStyle(color: AppColors.text, height: 1.5)),
          actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('OK'))],
        ));
      })),
      Card(color: AppColors.card, child: ListTile(leading: const Icon(Icons.upload_file, color: AppColors.primary), title: const Text('Export backup', style: TextStyle(color: AppColors.text)), onTap: () {
        Clipboard.setData(ClipboardData(text: app.exportBackupJson()));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
      })),
      Card(color: AppColors.card, child: ListTile(leading: const Icon(Icons.vpn_key_outlined, color: AppColors.primary), title: const Text('License', style: TextStyle(color: AppColors.text)), onTap: () => context.go('/license'))),
      Card(color: AppColors.card, child: ListTile(leading: const Icon(Icons.home_outlined, color: AppColors.primary), title: const Text('Roles', style: TextStyle(color: AppColors.text)), onTap: () => context.go('/'))),
    ]);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(app.bill.restaurantName.isEmpty ? titles[_tab] : '${app.bill.restaurantName} · ${titles[_tab]}'),
        actions: [if (_tab == 0) IconButton(onPressed: _settings, icon: const Icon(Icons.settings_outlined))],
      ),
      body: IndexedStack(index: _tab, children: [dash, tables, menu, stock, more]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.table_restaurant_outlined), selectedIcon: Icon(Icons.table_restaurant), label: 'Tables'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
