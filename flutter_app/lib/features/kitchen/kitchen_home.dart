import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class KitchenHome extends ConsumerStatefulWidget {
  const KitchenHome({super.key});
  @override
  ConsumerState<KitchenHome> createState() => _KitchenHomeState();
}

class _KitchenHomeState extends ConsumerState<KitchenHome> {
  final _ip = TextEditingController();

  Future<void> _ensureConnected() async {
    final app = ref.read(appControllerProvider);
    if (app.isMain || app.clientConnected) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect to Main'),
        content: TextField(
          controller: _ip,
          decoration: const InputDecoration(labelText: 'Main IP', prefixIcon: Icon(Icons.wifi)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await app.connectToMain(_ip.text.trim(), asRole: DeviceRole.kitchen);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Color _color(OrderStatus s) {
    switch (s) {
      case OrderStatus.open:
        return AppColors.danger;
      case OrderStatus.preparing:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _label(OrderStatus s) {
    switch (s) {
      case OrderStatus.open:
        return 'NEW';
      case OrderStatus.preparing:
        return 'COOKING';
      case OrderStatus.ready:
        return 'READY';
      default:
        return s.name.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final tickets = app.kitchenOrders;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
        actions: [
          if (!app.isMain && !app.clientConnected)
            IconButton(icon: const Icon(Icons.link_rounded), onPressed: _ensureConnected),
          IconButton(icon: const Icon(Icons.home_rounded), onPressed: () => context.go('/')),
        ],
      ),
      body: tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.soup_kitchen_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No kitchen tickets', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('New orders will appear here', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (_, i) {
                final o = tickets[i];
                final c = _color(o.status);
                return FadeSlideIn(
                  index: i,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.withOpacity(0.35), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: c.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.12),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
                                child: Text(_label(o.status),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Text('#${o.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                              const Spacer(),
                              if (o.tableNumber != null)
                                Row(children: [
                                  Icon(Icons.table_restaurant, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('Table ${o.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                ]),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            children: o.items
                                .map((it) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('${it.quantity}×',
                                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          child: Row(
                            children: [
                              if (o.status == OrderStatus.open)
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                                    onPressed: () => app.updateOrderStatus(o.id, OrderStatus.preparing),
                                    child: const Text('Start cooking'),
                                  ),
                                ),
                              if (o.status == OrderStatus.preparing)
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                                    onPressed: () => app.updateOrderStatus(o.id, OrderStatus.ready),
                                    child: const Text('Mark ready'),
                                  ),
                                ),
                              if (o.status == OrderStatus.ready)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => app.updateOrderStatus(o.id, OrderStatus.served),
                                    child: const Text('Served'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: (!app.isMain && !app.clientConnected)
          ? FloatingActionButton.extended(
              onPressed: _ensureConnected,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect'),
            )
          : null,
    );
  }
}
