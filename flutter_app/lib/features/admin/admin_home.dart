import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Main / Admin device home.
/// Starts the LocalServer, shows IP + QR, hosts menu/inventory/settings.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? localIp = '192.168.1.x';
  bool serverRunning = false;
  int port = 8787;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Device'),
        actions: [
          IconButton(
            icon: Icon(serverRunning ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              setState(() => serverRunning = !serverRunning);
              // TODO: call LocalServer.start / stop
            },
            tooltip: serverRunning ? 'Stop server' : 'Start server',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    serverRunning ? 'Server is running' : 'Server stopped',
                    style: TextStyle(
                      color: serverRunning ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Connect other devices to:'),
                  Text(
                    'http://$localIp:$port',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (localIp != null)
                    QrImageView(
                      data: 'orderflow://join?host=$localIp&port=$port',
                      size: 180,
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Other devices can scan this QR or enter the IP manually.\nFor unreliable Wi-Fi, turn on Hotspot on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AdminTile(
            icon: Icons.restaurant_menu,
            title: 'Menu Management',
            subtitle: 'Categories, items, prices, availability',
            onTap: () {},
          ),
          _AdminTile(
            icon: Icons.inventory_2,
            title: 'Inventory',
            subtitle: 'Stock levels & low-stock alerts (auto-deduct on)',
            onTap: () {},
          ),
          _AdminTile(
            icon: Icons.devices,
            title: 'Connected Devices',
            subtitle: 'See which tablets / phones are online',
            onTap: () {},
          ),
          _AdminTile(
            icon: Icons.receipt_long,
            title: 'Orders & Reports',
            subtitle: 'Today\'s sales, invoices, history',
            onTap: () {},
          ),
          _AdminTile(
            icon: Icons.print,
            title: 'Printers',
            subtitle: 'Kitchen & cashier printers (Network IP or Bluetooth)',
            onTap: () {},
          ),
          _AdminTile(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Tax, currency, restaurant name, grace period',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
