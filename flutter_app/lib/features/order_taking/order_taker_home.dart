import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class OrderTakerHome extends StatefulWidget {
  const OrderTakerHome({super.key});
  @override
  State<OrderTakerHome> createState() => _OrderTakerHomeState();
}

class _OrderTakerHomeState extends State<OrderTakerHome> {
  bool connected = false;
  String? mainHost;
  final _tableCtrl = TextEditingController();
  final _ipCtrl = TextEditingController(text: '192.168.1.10');
  final categories = const ['All', 'Mains', 'Drinks', 'Sides', 'Desserts'];
  String selectedCat = 'All';
  final cart = <_CartLine>[];
  final menu = const [
    _MenuItem('Grilled Chicken', 'Mains', 12.50),
    _MenuItem('Beef Burger', 'Mains', 11.00),
    _MenuItem('Pasta Alfredo', 'Mains', 10.50),
    _MenuItem('Fresh Juice', 'Drinks', 3.50),
    _MenuItem('Cola', 'Drinks', 2.00),
    _MenuItem('Fries', 'Sides', 3.00),
    _MenuItem('Salad', 'Sides', 4.50),
    _MenuItem('Cheesecake', 'Desserts', 5.50),
  ];

  List<_MenuItem> get filtered => selectedCat == 'All' ? menu : menu.where((m) => m.cat == selectedCat).toList();
  double get cartTotal => cart.fold(0.0, (s, l) => s + l.item.price * l.qty);

  void _showJoinSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Connect to Main', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Enter the IP shown on the Main device', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(controller: _ipCtrl, decoration: const InputDecoration(labelText: 'Main device IP', prefixIcon: Icon(Icons.lan_rounded), hintText: '192.168.1.10'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() { connected = true; mainHost = _ipCtrl.text.trim(); });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected to $mainHost'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.success));
              },
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect'),
            ),
          ]),
        );
      },
    );
  }

  void _addToCart(_MenuItem item) {
    setState(() {
      final i = cart.indexWhere((c) => c.item.name == item.name);
      if (i >= 0) cart[i] = _CartLine(item, cart[i].qty + 1);
      else cart.add(_CartLine(item, 1));
    });
  }

  void _submitOrder() {
    if (cart.isEmpty) return;
    final table = _tableCtrl.text.trim().isEmpty ? '—' : _tableCtrl.text.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send order?'),
        content: Text('Table / Ticket: $table\n${cart.length} line(s) · \$${cartTotal.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => cart.clear());
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order sent · Table $table'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.success));
            },
            child: const Text('Send to kitchen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Order Taker'),
          Text(connected ? 'Online · $mainHost' : 'Not connected', style: TextStyle(fontSize: 12, color: connected ? AppColors.success : Colors.grey, fontWeight: FontWeight.w500)),
        ]),
        actions: [
          IconButton(icon: Icon(connected ? Icons.link_rounded : Icons.link_off_rounded), onPressed: _showJoinSheet),
          IconButton(icon: const Icon(Icons.home_rounded), onPressed: () => context.go('/')),
        ],
      ),
      body: !connected
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 88, height: 88, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.point_of_sale_rounded, size: 44, color: AppColors.primary)),
              const SizedBox(height: 24),
              const Text('Connect to Main device', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Join the same Wi‑Fi or hotspot, then enter the Main IP.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 28),
              FilledButton.icon(onPressed: _showJoinSheet, icon: const Icon(Icons.link_rounded), label: const Text('Connect now')),
            ])))
          : Column(children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200)),
                child: TextField(controller: _tableCtrl, decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, prefixIcon: Icon(Icons.table_restaurant_rounded), hintText: 'Table # or Ticket #', contentPadding: EdgeInsets.symmetric(vertical: 12))),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    final sel = c == selectedCat;
                    return FilterChip(label: Text(c), selected: sel, onSelected: (_) => setState(() => selectedCat = c), selectedColor: AppColors.primary.withValues(alpha: 0.2), checkmarkColor: AppColors.primary);
                  },
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return FadeSlideIn(
                      index: i,
                      child: ScaleTap(
                        onTap: () => _addToCart(item),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary)),
                            ]),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
      bottomSheet: cart.isEmpty ? null : Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(child: Row(children: [
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${cart.fold<int>(0, (s, l) => s + l.qty)} items', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            Text('\$${cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          ])),
          FilledButton.icon(onPressed: _submitOrder, icon: const Icon(Icons.send_rounded), label: const Text('Send order')),
        ])),
      ),
      floatingActionButton: connected ? null : FloatingActionButton.extended(onPressed: _showJoinSheet, icon: const Icon(Icons.link_rounded), label: const Text('Connect to Main')),
    );
  }
}

class _MenuItem {
  final String name;
  final String cat;
  final double price;
  const _MenuItem(this.name, this.cat, this.price);
}

class _CartLine {
  final _MenuItem item;
  final int qty;
  const _CartLine(this.item, this.qty);
}
