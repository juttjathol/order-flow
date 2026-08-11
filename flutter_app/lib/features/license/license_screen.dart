import 'package:flutter/material.dart';

/// License activation & status.
/// Main device enters the key obtained from your Cloudflare dashboard.
class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _status;

  Future<void> _activate() async {
    setState(() {
      _loading = true;
      _status = null;
    });
    // TODO: call your Cloudflare /api/v1/license/validate
    // Store LicenseInfo in secure storage + local DB
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _status = 'Activation logic is ready – wire the HTTP call to your Worker URL.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License / Activation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the license key you received from the software provider. '
              'The Main device needs a valid license. Other devices only need to join the Main device.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'License Key',
                hintText: 'ABCD-EFGH-IJKL-MNOP',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _activate,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Activate'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(_status!, style: const TextStyle(color: Colors.orange)),
            ],
            const Spacer(),
            const Text(
              'After activation the app works fully offline. '
              'It only contacts the license server when internet is available '
              'to refresh the expiry date (long grace period applies).',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
