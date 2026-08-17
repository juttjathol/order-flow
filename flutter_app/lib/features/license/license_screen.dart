import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/state/app_controller.dart';
import '../../shared/theme/app_theme.dart';

class LicenseScreen extends ConsumerStatefulWidget {
  const LicenseScreen({super.key});
  @override
  ConsumerState<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends ConsumerState<LicenseScreen> {
  final _keyCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  bool _loading = false;
  bool _connectMode = false;

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/$kSupportWhatsAppUsername?text=${Uri.encodeComponent(kSupportWhatsAppMessage)}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp: @$kSupportWhatsAppUsername')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp: @$kSupportWhatsAppUsername')),
        );
      }
    }
  }

  Future<void> _activate() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) return;
    setState(() => _loading = true);
    final app = ref.read(appControllerProvider);
    final ok = await app.activateLicense(key);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok && ref.read(appControllerProvider).license != null) context.go('/');
  }

  Future<void> _connectToMain() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) return;
    setState(() => _loading = true);
    final app = ref.read(appControllerProvider);
    try {
      final ok = await app.connectToMain(host);
      if (!mounted) return;
      if (ok && app.clientConnected) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.licenseMessage ?? 'Could not connect. Check IP and Main is running.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connect failed: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final s = S(app.localeCode);
    final locked = app.licenseLocked;

    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Row(children: [
                Text(s.language, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                const Spacer(),
                TextButton(onPressed: () => app.setLocale('en'), child: const Text('EN')),
                TextButton(onPressed: () => app.setLocale('ur'), child: const Text('اردو')),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF166534), Color(0xFF22C55E)]),
                ),
                child: Column(children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 44),
                  const SizedBox(height: 12),
                  Text(s.appName, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    locked ? 'License inactive — get a new key' : s.tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _openWhatsApp,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.chat, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WhatsApp support', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                            Text('@$kSupportWhatsAppUsername', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            Text('Message for a license key', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
                    ]),
                  ),
                ),
              ),
              if (locked) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'This license was deleted or revoked. Contact WhatsApp for a new key.',
                    style: TextStyle(color: AppColors.text),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!locked)
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: !_connectMode ? AppColors.primary : AppColors.card,
                        foregroundColor: !_connectMode ? Colors.white : AppColors.muted,
                      ),
                      onPressed: () => setState(() => _connectMode = false),
                      child: const Text('Main device'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _connectMode ? AppColors.primary : AppColors.card,
                        foregroundColor: _connectMode ? Colors.white : AppColors.muted,
                      ),
                      onPressed: () => setState(() => _connectMode = true),
                      child: const Text('Connect to Main'),
                    ),
                  ),
                ]),
              const SizedBox(height: 16),
              if (_connectMode && !locked) ...[
                const Text('No license needed. Enter Main device IP.', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                TextField(
                  controller: _hostCtrl,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(labelText: 'Main IP', hintText: '192.168.1.10'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _connectToMain,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Connect'),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _keyCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.text, letterSpacing: 1.2),
                  decoration: InputDecoration(labelText: s.licenseKey, hintText: s.licenseHint),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _activate,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(s.activate),
                  ),
                ),
              ],
              if (app.licenseMessage != null) ...[
                const SizedBox(height: 12),
                Text(app.licenseMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary)),
              ],
              if (app.license != null && !locked) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(onPressed: () => context.go('/'), child: Text(s.continueApp)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
