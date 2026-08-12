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
        content: TextField(controller: _ip, decoration: const InputDecoration(labelText: 'Main IP')),
        actions: [
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
      case OrderStatus.open: return AppColors.danger;
      case OrderStatus.preparing: return AppColors.warning;
      case OrderStatus.ready: return AppColors.success;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final tickets = app.kitchenOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
        actions: [
          IconButton(icon: const Icon(Icons.link), onPressed: _ensureConnected),
          IconButton(icon: const Icon(Icons.home), onPressed: () => context.go('/')),
        ],
      ),
      body: tickets.isEmpty
          ? const Center(child: Text('No active kitchen tickets'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (_, i) {
                final o = tickets[i];
                final c = _color(o.status);
                return FadeSlideIn(
                  index: i,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: c.withValues(alpha: 0.12),
                        child: Row(children: [
                          Text('#${o.orderNumber}', style: TextStyle(fontWeight: FontWeight.w800, color: c)),
                          const SizedBox(width: 8),
                          Text(o.tableNumber ?? o.ticketNumber ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(o.status.name, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ...o.items.map((l) => Text('• ${l.nameSnapshot} ×${l.quantity}')),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: c),
                            onPressed: () {
                              if (o.status == OrderStatus.open) {
                                app.updateOrderStatus(o.id, OrderStatus.preparing);
                              } else if (o.status == OrderStatus.preparing) {
                                app.updateOrderStatus(o.id, OrderStatus.ready);
                              } else {
                                app.updateOrderStatus(o.id, OrderStatus.served);
                              }
                            },
                            child: Text(o.status == OrderStatus.open
                                ? 'Start preparing'
                                : o.status == OrderStatus.preparing
                                    ? 'Mark ready'
                                    : 'Clear'),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
      floatingActionButton: (!app.isMain && !app.clientConnected)
          ? FloatingActionButton.extended(onPressed: _ensureConnected, label: const Text('Connect'), icon: const Icon(Icons.link))
          : null,
    );
  }
}
