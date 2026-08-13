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
              await app.connectToMain(_ip.text.trim(), asRole: DeviceRole.cashier);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _paySheet(Order o) {
    final app = ref.read(appControllerProvider);
    final sym = app.bill.currencySymbol;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Text('Close order #${o.orderNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            if (o.tableNumber != null)
              Text('Table ${o.tableNumber}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text('TOTAL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  Text(
                    '$sym${o.total.asDouble.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...o.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${it.quantity}× ${it.nameSnapshot}'),
                      const Spacer(),
                      Text('$sym${it.lineTotal.asDouble.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                app.markPaid(o.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as paid · receipt queued')),
                );
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Mark paid'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                final preview = app.billPreviewFor(o);
                showDialog(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Bill preview'),
                    content: SingleChildScrollView(
                      child: SelectableText(preview, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close'))],
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Preview bill'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final open = app.openOrders;
    final paid = app.orders.where((o) => o.isPaid).toList().reversed.take(8).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sym = app.bill.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier'),
        actions: [
          if (!app.isMain && !app.clientConnected)
            IconButton(icon: const Icon(Icons.link_rounded), onPressed: _connect),
          IconButton(icon: const Icon(Icons.home_rounded), onPressed: () => context.go('/')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Today's sales", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    Text(
                      '$sym${app.todaySales.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Text('${open.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    const Text('open', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Unpaid orders', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.grey.shade800)),
          const SizedBox(height: 10),
          if (open.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                Icon(Icons.point_of_sale_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No unpaid orders', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ]),
            )
          else
            ...open.asMap().entries.map((e) {
              final o = e.value;
              return FadeSlideIn(
                index: e.key,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ScaleTap(
                    onTap: () => _paySheet(o),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('#${o.orderNumber}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 13)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                o.tableNumber != null ? 'Table ${o.tableNumber}' : (o.ticketNumber ?? 'Walk-in'),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              Text(
                                '${o.items.length} lines · ${o.status.name}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ]),
                          ),
                          Text(
                            '$sym${o.total.asDouble.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.primary),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (paid.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Recently paid', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            ...paid.map((o) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                  ),
                  title: Text('#${o.orderNumber}${o.tableNumber != null ? ' · T${o.tableNumber}' : ''}'),
                  trailing: Text('$sym${o.total.asDouble.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                )),
          ],
        ],
      ),
      floatingActionButton: (!app.isMain && !app.clientConnected)
          ? FloatingActionButton.extended(onPressed: _connect, icon: const Icon(Icons.link_rounded), label: const Text('Connect'))
          : null,
    );
  }
}
