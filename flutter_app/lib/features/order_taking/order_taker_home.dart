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
  final table = TextEditingController();
  final ticket = TextEditingController();
  String orderType = 'dine_in'; // dine_in | takeaway | delivery
  final host = TextEditingController();
  final List<OrderItem> cart = [];
  String? selectedCat;
  String? _addToOrderId;

  double get cartTotal => cart.fold(0, (s, i) => s + i.lineTotal.asDouble);

  void _add(MenuItem m) {
    setState(() {
      final i = cart.indexWhere((e) => e.menuItemId == m.id);
      if (i >= 0) {
        final old = cart[i];
        cart[i] = OrderItem(
          menuItemId: old.menuItemId,
          nameSnapshot: old.nameSnapshot,
          unitPrice: old.unitPrice,
          quantity: old.quantity + 1,
          notes: old.notes,
        );
      } else {
        cart.add(OrderItem(menuItemId: m.id, nameSnapshot: m.name, unitPrice: m.price, quantity: 1));
      }
    });
  }

  Future<void> _send() async {
    final app = ref.read(appControllerProvider);
    if (cart.isEmpty) return;
    if (_addToOrderId != null) {
      app.addItemsToOrder(_addToOrderId!, List.from(cart));
    } else {
      app.createOrder(
        tableNumber: table.text.trim().isEmpty ? null : table.text.trim(),
        ticketNumber: ticket.text.trim().isEmpty ? null : ticket.text.trim(),
        items: List.from(cart),
      );
    }
    setState(() {
      cart.clear();
      _addToOrderId = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Order sent to kitchen'),
        ),
      );
    }
  }

  Future<void> _connect() async {
    final app = ref.read(appControllerProvider);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect to Main'),
        content: TextField(
          controller: host,
          decoration: const InputDecoration(
            labelText: 'Main device IP',
            hintText: '192.168.1.10',
            prefixIcon: Icon(Icons.wifi),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await app.connectToMain(host.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Connected' : 'Failed to connect')),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cats = ['All', ...app.categories.map((c) => c.name)];
    selectedCat ??= 'All';
    final items = selectedCat == 'All'
        ? app.menuItems
        : app.menuItems.where((m) {
            final c = app.categories.where((x) => x.id == m.categoryId);
            return c.isNotEmpty && c.first.name == selectedCat;
          }).toList();
    final sym = app.bill.currencySymbol;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Order taker'),
        actions: [
          if (!app.isMain && !app.clientConnected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilledButton.tonalIcon(
                onPressed: _connect,
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Connect'),
              ),
            ),
          IconButton(icon: const Icon(Icons.home_rounded), onPressed: () => context.go('/')),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: table,
                      decoration: const InputDecoration(
                        labelText: 'Table',
                        prefixIcon: Icon(Icons.table_restaurant_rounded),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ticket,
                      decoration: const InputDecoration(
                        labelText: 'Ticket #',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                        isDense: true,
                      ),
                    ),
                  ),
                ]),
                if (app.openOrders.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add more to open table',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: app.openOrders.map((o) {
                        final selected = _addToOrderId == o.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: selected,
                            label: Text('T${o.tableNumber ?? '—'} · #${o.orderNumber}'),
                            onSelected: (_) => setState(() => _addToOrderId = selected ? null : o.id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: cats.asMap().entries.map((e) {
                final c = e.value;
                final selected = selectedCat == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FadeSlideIn(
                    index: e.key,
                    child: FilterChip(
                      label: Text(c, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedCat = c),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No menu items'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final m = items[i];
                      return FadeSlideIn(
                        index: i % 8,
                        child: ScaleTap(
                          onTap: () => _add(m),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                                    : [Colors.white, const Color(0xFFF8FAFC)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.25)),
                                Row(
                                  children: [
                                    Text(
                                      '$sym${m.price.asDouble.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: cart.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4)),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$sym${cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                          ),
                          Text(
                            '${cart.fold<int>(0, (s, l) => s + l.quantity)} items'
                            '${_addToOrderId != null ? ' · add to table' : ''}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(_addToOrderId != null ? 'Add' : 'Send'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
