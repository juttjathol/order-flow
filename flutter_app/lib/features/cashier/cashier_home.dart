import 'package:flutter/material.dart';

class CashierHome extends StatelessWidget {
  const CashierHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {},
            tooltip: 'Connect to Main',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Open tables / tickets appear here.\nApply discounts, print payment tickets, mark paid, generate invoices.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
