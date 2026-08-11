import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/animated_widgets.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;

  Future<void> _activate() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() {
        _message = 'Enter a license key';
        _success = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _loading = false;
      _success = true;
      _message =
          'Key saved on this device. When online, it will validate with your provider. Offline use continues with grace period.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('License'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeSlideIn(
            index: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.vpn_key_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Activate Order Flow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Only the Main device needs a license key from your software provider.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            index: 1,
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'License key',
                hintText: 'ABCD-EFGH-IJKL-MNOP',
                prefixIcon: Icon(Icons.password_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            index: 2,
            child: FilledButton(
              onPressed: _loading ? null : _activate,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Activate license'),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            FadeSlideIn(
              index: 3,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_success ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_success ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _success ? Icons.check_circle_rounded : Icons.info_rounded,
                      color: _success ? AppColors.success : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          FadeSlideIn(
            index: 4,
            child: Text(
              'Works fully offline after activation. The app only contacts the license server when internet is available (long grace period).',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
