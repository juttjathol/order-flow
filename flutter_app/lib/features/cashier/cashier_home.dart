import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class CashierHome extends StatefulWidget {
  const CashierHome({super.key});

  @override
  State<CashierHome> createState() => _CashierHomeState();
}

class _CashierHomeState extends State<CashierHome> {
  final bills = <_Bill>[
    _Bill('T-04', 28.50, 'Open', 3),
    _Bill('T-07', 26.00, 'Open', 4),
    _Bill('T-12', 15.00, 'Paid', 2),
  ];

  void _closeBill(_Bill b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Close ${b.table}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('\$${b.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() => b.status = 'Paid');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Marked paid'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                  ));
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Mark paid'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.print_rounded),
                label: const Text('Print receipt only'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final open = bills.where((b) => b.status == 'Open').toList();
    final paid = bills.where((b) => b.status == 'Paid').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier'),
        actions: [
          IconButton(icon: const Icon(Icons.home_rounded), onPressed: () => context.go('/')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: StatCard(label: 'Open bills', value: '${open.length}', icon: Icons.receipt_long_rounded, color: AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(child: StatCard(label: 'Open total', value: '\$${open.fold<double>(0, (s, b) => s + b.total).toStringAsFixed(0)}', icon: Icons.payments_rounded, color: AppColors.primary)),
          ]),
          const SizedBox(height: 24),
          Text('Open tables', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 10),
          ...open.asMap().entries.map((e) {
            final b = e.value;
            return FadeSlideIn(
              index: e.key,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ScaleTap(
                  onTap: () => _closeBill(b),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48, alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Text(b.table.replaceAll('T-', ''), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.table, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${b.items} items', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ])),
                      Text('\$${b.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                    ]),
                  ),
                ),
              ),
            );
          }),
          if (paid.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Recently paid', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 10),
            ...paid.map((b) => ListTile(
                  leading: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                  title: Text(b.table),
                  trailing: Text('\$${b.total.toStringAsFixed(2)}'),
                )),
          ],
        ],
      ),
    );
  }
}

class _Bill {
  final String table;
  final double total;
  String status;
  final int items;
  _Bill(this.table, this.total, this.status, this.items);
}
