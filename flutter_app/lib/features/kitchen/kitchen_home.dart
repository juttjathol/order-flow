import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class KitchenHome extends StatefulWidget {
  const KitchenHome({super.key});

  @override
  State<KitchenHome> createState() => _KitchenHomeState();
}

class _KitchenHomeState extends State<KitchenHome> {
  final tickets = <_Ticket>[
    _Ticket(1, 'T-04', ['Grilled Chicken x1', 'Fries x2'], 'New', DateTime.now().subtract(const Duration(minutes: 2))),
    _Ticket(2, 'T-07', ['Beef Burger x2', 'Cola x2'], 'Preparing', DateTime.now().subtract(const Duration(minutes: 8))),
    _Ticket(3, 'T-02', ['Pasta Alfredo x1', 'Salad x1'], 'New', DateTime.now().subtract(const Duration(minutes: 1))),
  ];

  Color _statusColor(String s) {
    switch (s) {
      case 'New':
        return AppColors.danger;
      case 'Preparing':
        return AppColors.warning;
      case 'Ready':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  void _advance(_Ticket t) {
    setState(() {
      if (t.status == 'New') {
        t.status = 'Preparing';
      } else if (t.status == 'Preparing') {
        t.status = 'Ready';
      } else {
        tickets.remove(t);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.soup_kitchen_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No active tickets', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (_, i) {
                final t = tickets[i];
                final color = _statusColor(t.status);
                final mins = DateTime.now().difference(t.created).inMinutes;
                return FadeSlideIn(
                  index: i,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              Text('#${t.id}', style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                                child: Text(t.table, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                              const Spacer(),
                              Text('${mins}m', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                child: Text(t.status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...t.items.map((line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(children: [
                                      const Icon(Icons.circle, size: 6, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(line, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                    ]),
                                  )),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => _advance(t),
                                  style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                                  child: Text(t.status == 'New' ? 'Start preparing' : t.status == 'Preparing' ? 'Mark ready' : 'Clear ticket'),
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
    );
  }
}

class _Ticket {
  final int id;
  final String table;
  final List<String> items;
  String status;
  final DateTime created;
  _Ticket(this.id, this.table, this.items, this.status, this.created);
}
