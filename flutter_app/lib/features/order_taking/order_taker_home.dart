import 'package:flutter/material.dart';

/// Order Taker device.
/// Flow:
/// 1. Connect to Main (auto / QR / IP)
/// 2. Browse menu (synced from Main)
/// 3. Build cart → choose Table # or Ticket #
/// 4. Submit → order appears everywhere + kitchen print
/// 5. Can reopen open orders to add more items
class OrderTakerHome extends StatelessWidget {
  const OrderTakerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Taker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () {
              // TODO: show join dialog (discover / QR / manual IP)
            },
            tooltip: 'Connect to Main',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Connect to a Main device first.\nThen select a table and start taking orders.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: new order
        },
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }
}
