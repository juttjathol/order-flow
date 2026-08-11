import 'package:flutter/material.dart';

class KitchenHome extends StatelessWidget {
  const KitchenHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
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
          'Live orders will appear here once connected to Main.\nMark items / orders as Preparing → Ready → Served.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
