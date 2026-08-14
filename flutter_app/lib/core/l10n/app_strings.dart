import 'dart:ui' show TextDirection;

/// Lightweight EN / UR strings used across the app.
class S {
  final String code;
  S(this.code);

  bool get isUrdu => code == 'ur';
  TextDirection get direction => isUrdu ? TextDirection.rtl : TextDirection.ltr;

  String get appName => isUrdu ? 'آرڈر فلو' : 'Order Flow';
  String get tagline => isUrdu
      ? 'آف لائن آرڈر سسٹم — میز، کچن، کیشئر'
      : 'Offline order system — tables, kitchen, cashier';
  String get language => isUrdu ? 'زبان' : 'Language';
  String get english => 'English';
  String get urdu => 'اردو';
  String get activateTitle => isUrdu ? 'لائسنس فعال کریں' : 'Activate license';
  String get activateHint => isUrdu
      ? 'مین ڈیوائس پر لائسنس کلید درج کریں۔ باقی فون مقامی نیٹ ورک سے جڑتے ہیں۔'
      : 'Enter the license key on the Main device. Other phones join the local network.';
  String get licenseKey => isUrdu ? 'لائسنس کلید' : 'License key';
  String get activate => isUrdu ? 'فعال کریں' : 'Activate';
  String get contactWhatsApp => isUrdu ? 'واٹس ایپ پر رابطہ' : 'Contact on WhatsApp';
}
