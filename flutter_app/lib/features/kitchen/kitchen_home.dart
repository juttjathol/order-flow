import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';

class KitchenHome extends ConsumerWidget {
  const KitchenHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final tickets = app.kitchenOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(appControllerProvider).notifyListeners(),
          ),
        ],
      ),
      body: tickets.isEmpty
          ? const Center(child: Text('No open kitchen tickets'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tickets.length,
              itemBuilder: (_, i) {
                final o = tickets[i];
                final color = o.status == OrderStatus.ready
                    ? AppColors.success
                    : o.status == OrderStatus.preparing
                        ? AppColors.warn
                        : AppColors.primary;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${o.orderNumber}',
                                style: TextStyle(
                                    color: color, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              o.tableNumber != null
                                  ? 'Table ${o.tableNumber}'
                                  : (o.ticketNumber ?? 'Walk-in'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(o.status.name,
                                style: TextStyle(color: color, fontSize: 12)),
                          ],
                        ),
                        const Divider(height: 16),
                        ...o.items.map(
                          (it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              '${it.quantity}× ${it.nameSnapshot}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (o.status == OrderStatus.open)
                              FilledButton(
                                onPressed: () => ref
                                    .read(appControllerProvider)
                                    .updateOrderStatus(o.id, OrderStatus.preparing),
                                child: const Text('Start'),
                              ),
                            if (o.status == OrderStatus.preparing)
                              FilledButton(
                                onPressed: () => ref
                                    .read(appControllerProvider)
                                    .updateOrderStatus(o.id, OrderStatus.ready),
                                child: const Text('Ready'),
                              ),
                            if (o.status == OrderStatus.ready)
                              FilledButton(
                                onPressed: () => ref
                                    .read(appControllerProvider)
                                    .updateOrderStatus(o.id, OrderStatus.served),
                                child: const Text('Served'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
