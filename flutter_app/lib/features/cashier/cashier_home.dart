import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class CashierHome extends ConsumerStatefulWidget {
  const CashierHome({super.key});
  @override
  ConsumerState<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends ConsumerState<CashierHome> {
  final _ip = TextEditingController();

  Future<void> _connect() async {
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
              await app.connectToMain(_ip.text.trim(), asRole: DeviceRole.cashier);
              if (ctx.mounted) Navigator.pop(ctx);
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
    final open = app.openOrders.where((o) => !o.isPaid).toList();
    final paid = app.orders.where((o) => o.isPaid).toList().reversed.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier'),
        actions: [
          IconButton(icon: const Icon(Icons.link), onPressed: _connect),
          IconButton(icon: const Icon(Icons.home), onPressed: () => context.go('/')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: StatCard(label: 'Open bills', value: '${open.length}', icon: Icons.receipt_long, color: AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Open total',
                value: '\$${open.fold<double>(0, (s, o) => s + o.total.asDouble).toStringAsFixed(0)}',
                icon: Icons.payments,
                color: AppColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Open tables', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...open.map((o) => Card(
                child: ListTile(
                  title: Text('#${o.orderNumber} · ${o.tableNumber ?? o.ticketNumber ?? '—'}'),
                  subtitle: Text('${o.items.length} lines · ${o.status.name}'),
                  trailing: Text('\$${o.total.asDouble.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text('Close #${o.orderNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('\$${o.total.asDouble.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              app.markPaid(o.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Mark paid'),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              )),
          if (paid.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Recently paid', style: TextStyle(fontWeight: FontWeight.w700)),
            ...paid.map((o) => ListTile(
                  leading: const Icon(Icons.check_circle, color: AppColors.success),
                  title: Text('#${o.orderNumber}'),
                  trailing: Text('\$${o.total.asDouble.toStringAsFixed(2)}'),
                )),
          ],
        ],
      ),
      floatingActionButton: (!app.isMain && !app.clientConnected)
          ? FloatingActionButton.extended(onPressed: _connect, icon: const Icon(Icons.link), label: const Text('Connect'))
          : null,
    );
  }
}
