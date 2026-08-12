import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class OrderTakerHome extends ConsumerStatefulWidget {
  const OrderTakerHome({super.key});
  @override
  ConsumerState<OrderTakerHome> createState() => _OrderTakerHomeState();
}

class _OrderTakerHomeState extends ConsumerState<OrderTakerHome> {
  final _tableCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  String selectedCat = 'All';
  final cart = <OrderItem>[];
  bool _connecting = false;
  String? _addToOrderId;

  double get cartTotal => cart.fold(0.0, (s, l) => s + l.lineTotal.asDouble);

  Future<void> _connect() async {
    final host = _ipCtrl.text.trim();
    if (host.isEmpty) return;
    setState(() => _connecting = true);
    final ok = await ref.read(appControllerProvider).connectToMain(host, asRole: DeviceRole.orderTaker);
    setState(() => _connecting = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Connected' : 'Could not connect — check IP and Main server'),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showJoin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Connect to Main', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: _ipCtrl, decoration: const InputDecoration(labelText: 'Main IP', prefixIcon: Icon(Icons.lan))),
              const SizedBox(height: 12),
              FilledButton(onPressed: _connecting ? null : _connect, child: Text(_connecting ? 'Connecting…' : 'Connect')),
            ]),
          ),
        );
      },
    );
  }

  void _onTableChanged(String v) {
    final app = ref.read(appControllerProvider);
    setState(() => _addToOrderId = app.findOpenByTable(v)?.id);
  }

  void _add(MenuItem m) {
    setState(() {
      final i = cart.indexWhere((c) => c.menuItemId == m.id);
      if (i >= 0) cart[i] = cart[i].copyWith(quantity: cart[i].quantity + 1);
      else cart.add(OrderItem(menuItemId: m.id, nameSnapshot: m.name, unitPrice: m.price));
    });
  }

  void _send() {
    if (cart.isEmpty) return;
    final app = ref.read(appControllerProvider);
    if (!app.isMain && !app.clientConnected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connect to Main first')));
      return;
    }
    final table = _tableCtrl.text.trim();
    if (_addToOrderId != null) {
      app.addItemsToOrder(_addToOrderId!, List.from(cart));
      setState(() { cart.clear(); _addToOrderId = app.findOpenByTable(table)?.id; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Items added to table $table'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      return;
    }
    app.createOrder(
      tableNumber: table.isEmpty ? null : table,
      ticketNumber: table.isEmpty ? 'T-${DateTime.now().millisecondsSinceEpoch % 10000}' : null,
      items: List.from(cart),
    );
    setState(() { cart.clear(); _addToOrderId = table.isEmpty ? null : app.findOpenByTable(table)?.id; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(table.isEmpty ? 'Order sent' : 'Order sent · Table $table'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final ready = app.isMain || app.clientConnected;
    final cats = ['All', ...app.categories.map((c) => c.name)];
    final items = selectedCat == 'All'
        ? app.menuItems.where((m) => m.isAvailable).toList()
        : app.menuItems.where((m) {
            final cat = app.categories.where((c) => c.id == m.categoryId);
            return m.isAvailable && cat.isNotEmpty && cat.first.name == selectedCat;
          }).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Order Taker'),
          Text(ready ? (app.isMain ? 'Main mode' : 'Online · ${app.connectedHost}') : 'Not connected', style: TextStyle(fontSize: 12, color: ready ? AppColors.success : Colors.grey)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.link), onPressed: _showJoin),
          IconButton(icon: const Icon(Icons.home), onPressed: () => context.go('/')),
        ],
      ),
      body: !ready
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.point_of_sale, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Connect to Main device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: _showJoin, icon: const Icon(Icons.link), label: const Text('Connect')),
            ]))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _tableCtrl,
                  onChanged: _onTableChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.table_restaurant),
                    hintText: 'Table # or Ticket #',
                    suffixIcon: _addToOrderId != null ? const Padding(padding: EdgeInsets.only(right: 8), child: Chip(label: Text('ADD MORE'), visualDensity: VisualDensity.compact)) : null,
                  ),
                ),
              ),
              if (_addToOrderId != null)
                Material(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Open order for this table — new items will be added.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: cats.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(label: Text(c), selected: selectedCat == c, onSelected: (_) => setState(() => selectedCat = c)),
                  )).toList(),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final m = items[i];
                    return ScaleTap(
                      onTap: () => _add(m),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('\$${m.price.asDouble.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
      bottomSheet: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: SafeArea(
                child: Row(children: [
                  Expanded(child: Text('\$${cartTotal.toStringAsFixed(2)} · ${cart.fold<int>(0, (s, l) => s + l.quantity)} items', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  FilledButton.icon(onPressed: _send, icon: const Icon(Icons.send), label: Text(_addToOrderId != null ? 'Add to order' : 'Send')),
                ]),
              ),
            ),
    );
  }
}
