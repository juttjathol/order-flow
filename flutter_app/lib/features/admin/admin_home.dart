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
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
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
          FilledButton.icon(onPressed: () {
            final name = TextEditingController();
            final price = TextEditingController(text: '10.00');
            showDialog(context: context, builder: (dCtx) => AlertDialog(
              title: const Text('Add item'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: price, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              ]),
              actions: [FilledButton(onPressed: () {
                final catId = app.categories.isNotEmpty ? app.categories.first.id : 'general';
                if (app.categories.isEmpty) app.upsertCategory(MenuCategory(id: catId, name: 'General'));
                final cents = ((double.tryParse(price.text) ?? 0) * 100).round();
                app.upsertMenuItem(MenuItem(categoryId: catId, name: name.text.trim(), price: Money(cents)));
                Navigator.pop(dCtx); Navigator.pop(ctx);
              }, child: const Text('Add'))],
            ));
          }, icon: const Icon(Icons.add), label: const Text('Add menu item')),
        ]),
      );
    });
  }

  void _inventory() {
    final app = ref.read(appControllerProvider);
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.85,
      builder: (_, sc) => Padding(padding: const EdgeInsets.all(16), child: ListView(controller: sc, children: [
        const Text('Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () {
          final name = TextEditingController();
          final qty = TextEditingController(text: '0');
          final unit = TextEditingController(text: 'pcs');
          showDialog(context: context, builder: (d) => AlertDialog(
            title: const Text('Add inventory item'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: qty, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')),
            ]),
            actions: [FilledButton(onPressed: () {
              if (name.text.trim().isEmpty) return;
              app.addInventoryItem(name: name.text.trim(), quantity: double.tryParse(qty.text) ?? 0, unit: unit.text.trim().isEmpty ? 'pcs' : unit.text.trim());
              Navigator.pop(d); Navigator.pop(ctx);
            }, child: const Text('Add'))],
          ));
        }, icon: const Icon(Icons.add), label: const Text('Add item')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () {
          final csv = TextEditingController();
          showDialog(context: context, builder: (d) => AlertDialog(
            title: const Text('Import CSV / Excel'),
            content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Excel: File → Save As → CSV, paste here.\nColumns: name, quantity, unit, lowStock', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(controller: csv, maxLines: 8, decoration: const InputDecoration(hintText: 'Flour,25,kg,5', border: OutlineInputBorder())),
            ])),
            actions: [
              TextButton(onPressed: () {
                final n = app.importInventoryLines(csv.text);
                Navigator.pop(d);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $n items')));
                Navigator.pop(ctx);
              }, child: const Text('As lines')),
              FilledButton(onPressed: () {
                final n = app.importInventoryCsv(csv.text);
                Navigator.pop(d);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $n items')));
                Navigator.pop(ctx);
              }, child: const Text('Import CSV')),
            ],
          ));
        }, icon: const Icon(Icons.upload_file), label: const Text('Import Excel/CSV')),
        const Divider(),
        ...app.inventory.map((inv) => ListTile(
          title: Text(inv.name),
          subtitle: Text('Stock: ${inv.quantity.toStringAsFixed(0)} ${inv.unit}'),
          trailing: inv.quantity <= inv.lowStockThreshold
              ? const Text('LOW', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800))
              : IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { app.deleteInventoryItem(inv.id); Navigator.pop(ctx); }),
          onTap: () {
            final c = TextEditingController(text: inv.quantity.toStringAsFixed(0));
            showDialog(context: context, builder: (d) => AlertDialog(
              title: Text(inv.name),
              content: TextField(controller: c, keyboardType: TextInputType.number),
              actions: [FilledButton(onPressed: () {
                app.setInventoryQty(inv.id, double.tryParse(c.text) ?? inv.quantity);
                Navigator.pop(d); Navigator.pop(ctx);
              }, child: const Text('Save'))],
            ));
          },
        )),
      ])),
    ));
  }

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
    showDialog(context: context, builder: (d) => AlertDialog(
      title: const Text('Bill & printers'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Restaurant name')),
        TextField(controller: addr, decoration: const InputDecoration(labelText: 'Address')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
        TextField(controller: tax, decoration: const InputDecoration(labelText: 'Tax ID')),
        TextField(controller: footer, decoration: const InputDecoration(labelText: 'Receipt footer')),
        TextField(controller: cur, decoration: const InputDecoration(labelText: 'Currency symbol')),
        const Divider(),
        TextField(controller: kitchen, decoration: const InputDecoration(labelText: 'Kitchen printer IP')),
        TextField(controller: cashier, decoration: const InputDecoration(labelText: 'Cashier printer IP')),
      ])),
      actions: [
        TextButton(onPressed: () async {
          final ok = await app.testKitchenPrinter();
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Kitchen test sent' : 'Kitchen print failed')));
        }, child: const Text('Test kitchen')),
        TextButton(onPressed: () async {
          final ok = await app.testCashierPrinter();
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Cashier test sent' : 'Cashier print failed')));
        }, child: const Text('Test cashier')),
        FilledButton(onPressed: () async {
          await app.saveSettings(
            billProfile: BillProfile(
              restaurantName: name.text.trim().isEmpty ? 'My Restaurant' : name.text.trim(),
              address: addr.text.trim(),
              phone: phone.text.trim(),
              taxId: tax.text.trim(),
              footer: footer.text.trim().isEmpty ? 'Thank you!' : footer.text.trim(),
              currencySymbol: cur.text.trim().isEmpty ? '\$' : cur.text.trim(),
            ),
            kitchenIp: kitchen.text.trim(),
            cashierIp: cashier.text.trim(),
          );
          if (d.mounted) Navigator.pop(d);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill settings saved')));
        }, child: const Text('Save')),
      ],
    ));
  }

  void _reports() {
    final app = ref.read(appControllerProvider);
    final r = app.salesReport(days: 1);
    showDialog(context: context, builder: (d) => AlertDialog(
      title: const Text('Today report'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Orders paid: ${r['orders']}'),
        Text('Sales: ${r['currency']}${(r['total'] as double).toStringAsFixed(2)}'),
        Text('Low stock items: ${r['lowStock']}'),
        Text('Open tables: ${app.openOrders.length}'),
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('OK'))],
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
            const Text('PC: open this URL to manage inventory & bill', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
        StatCard(label: "Today's sales", value: '${app.bill.currencySymbol}${app.todaySales.toStringAsFixed(2)}', icon: Icons.trending_up, color: AppColors.success),
        const SizedBox(height: 16),
        Card(child: ListTile(leading: const Icon(Icons.restaurant_menu, color: AppColors.primary), title: const Text('Menu'), onTap: _menuEditor)),
        Card(child: ListTile(leading: const Icon(Icons.inventory_2, color: AppColors.primary), title: const Text('Inventory'), subtitle: const Text('Add item · Import Excel/CSV'), onTap: _inventory)),
        Card(child: ListTile(leading: const Icon(Icons.receipt, color: AppColors.primary), title: const Text('Bill & printers'), subtitle: Text(app.bill.restaurantName), onTap: _settings)),
        Card(child: ListTile(leading: const Icon(Icons.bar_chart, color: AppColors.primary), title: const Text('Today report'), onTap: _reports)),
        Card(child: ListTile(leading: const Icon(Icons.receipt_long, color: AppColors.primary), title: Text('Orders (${app.orders.length})'), onTap: () {
          showModalBottomSheet(context: context, builder: (_) => ListView(children: app.orders.reversed.map((o) => ListTile(
            title: Text('#${o.orderNumber} · ${o.tableNumber ?? '—'}'),
            subtitle: Text('${o.status.name} · ${app.bill.currencySymbol}${o.total.asDouble.toStringAsFixed(2)}'),
          )).toList()));
        })),
        const SizedBox(height: 8),
        Text('Today: ${app.todayOrderCount} orders', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.home), label: const Text('Back to roles')),
      ]),
    );
  }
}
