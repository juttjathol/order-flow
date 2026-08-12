import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';

class LicenseScreen extends ConsumerStatefulWidget {
  const LicenseScreen({super.key});
  @override
  ConsumerState<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends ConsumerState<LicenseScreen> {
  final _c = TextEditingController();
  bool _loading = false;

  Future<void> _activate() async {
    setState(() => _loading = true);
    await ref.read(appControllerProvider).activateLicense(_c.text.trim());
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('License'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(children: [
              Icon(Icons.vpn_key, color: Colors.white, size: 40),
              SizedBox(height: 12),
              Text('Activate Order Flow', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('Main device needs a license key from your provider.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 24),
          if (app.license != null) ...[
            Text('Current: ${app.license!.key}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Customer: ${app.license!.customerName}'),
            Text('Expires: ${app.license!.expiresAt.toLocal().toString().split('.').first}'),
            const SizedBox(height: 16),
          ],
          TextField(controller: _c, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'License key', hintText: 'ABCD-EFGH-...')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _activate,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Activate'),
          ),
          if (app.licenseMessage != null) ...[
            const SizedBox(height: 16),
            Text(app.licenseMessage!, style: const TextStyle(color: AppColors.warning)),
          ],
        ],
      ),
    );
  }
}
