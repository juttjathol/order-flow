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
  final _c = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;

  Future<void> _activate() async {
    final key = _c.text.trim();
    if (key.isEmpty) return;
    setState(() => _loading = true);
    final app = ref.read(appControllerProvider);
    if (_name.text.trim().isNotEmpty || _email.text.trim().isNotEmpty) {
      await app.registerSignup(name: _name.text.trim(), phone: '', email: _email.text.trim());
    }
    await app.activateLicense(key);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ref.read(appControllerProvider).license != null) {
      context.go('/');
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/$kSupportWhatsApp?text=${Uri.encodeComponent(kSupportWhatsAppMessage)}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp: +$kSupportWhatsApp')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp: +$kSupportWhatsApp')),
        );
      }
    }
  }

  TextStyle _urdu(double size, {Color? color, FontWeight? w}) =>
      GoogleFonts.notoNastaliqUrdu(fontSize: size, color: color, fontWeight: w, height: 1.7);

  InputDecoration _fieldDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final s = S(app.localeCode);
    final licensed = app.license != null;

    return Directionality(
      textDirection: s.direction,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF0C4A6E), Color(0xFF134E4A)],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Row(children: [
                  Text(s.language,
                      style: s.isUrdu ? _urdu(13, color: Colors.white60) : const TextStyle(color: Colors.white60, fontSize: 13)),
                  const Spacer(),
                  _LangChip(label: s.english, selected: !s.isUrdu, onTap: () => app.setLocale('en')),
                  const SizedBox(width: 8),
                  _LangChip(label: s.urdu, selected: s.isUrdu, onTap: () => app.setLocale('ur'), urdu: true),
                ]),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)]),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Column(children: [
                    const Icon(Icons.storefront_rounded, color: Colors.white, size: 48),
                    const SizedBox(height: 14),
                    Text(s.appName,
                        textAlign: TextAlign.center,
                        style: s.isUrdu
                            ? _urdu(26, color: Colors.white, w: FontWeight.w700)
                            : const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(s.tagline,
                        textAlign: TextAlign.center,
                        style: s.isUrdu ? _urdu(15, color: Colors.white70) : const TextStyle(color: Colors.white70, height: 1.4)),
                  ]),
                ),
                const SizedBox(height: 28),
                Text(s.activateTitle,
                    style: s.isUrdu
                        ? _urdu(22, color: Colors.white, w: FontWeight.w700)
                        : const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text(s.activateHint,
                    style: s.isUrdu ? _urdu(14, color: Colors.white60) : const TextStyle(color: Colors.white60, height: 1.4)),
                const SizedBox(height: 20),
                Material(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _openWhatsApp,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.chat, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.contactWhatsApp,
                                style: s.isUrdu
                                    ? _urdu(16, color: Colors.white, w: FontWeight.w700)
                                    : const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                            const Text('+60 11-2897 9730', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(s.whatsAppSub,
                                style: s.isUrdu ? _urdu(12, color: Colors.white54) : const TextStyle(color: Colors.white54, fontSize: 12)),
                          ]),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(s.isUrdu ? 'نام' : 'Your name',
                    style: s.isUrdu ? _urdu(15, color: Colors.white70) : const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: _fieldDec(s.isUrdu ? 'ریستوراں / آپ کا نام' : 'Restaurant or your name')),
                const SizedBox(height: 12),
                Text(s.isUrdu ? 'ای میل' : 'Email',
                    style: s.isUrdu ? _urdu(15, color: Colors.white70) : const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: _fieldDec('you@restaurant.com')),
                const SizedBox(height: 16),
                Text(s.licenseKey,
                    style: s.isUrdu ? _urdu(15, color: Colors.white70) : const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _c,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
                  decoration: _fieldDec(s.licenseHint),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _activate,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.activate,
                            style: s.isUrdu
                                ? _urdu(18, w: FontWeight.w700)
                                : const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                if (app.licenseMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(app.licenseMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7DD3FC))),
                ],
                if (licensed) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.success.withOpacity(0.4)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${s.currentLicense}: ${app.license!.key}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      Text('${s.expires}: ${app.license!.expiresAt.toLocal().toString().split('.').first}',
                          style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(onPressed: () => context.go('/'), child: Text(s.continueApp)),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool urdu;
  const _LangChip({required this.label, required this.selected, required this.onTap, this.urdu = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: urdu
                ? GoogleFonts.notoNastaliqUrdu(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? const Color(0xFF0F172A) : Colors.white,
                  )
                : TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? const Color(0xFF0F172A) : Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
