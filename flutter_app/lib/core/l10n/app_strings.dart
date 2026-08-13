import 'dart:ui' show TextDirection;

class S {
  final String code;
  const S(this.code);
  bool get isUrdu => code == 'ur';
  TextDirection get direction => isUrdu ? TextDirection.rtl : TextDirection.ltr;
  String get appName => isUrdu ? 'آرڈر فلو' : 'Order Flow';
  String get tagline => isUrdu ? 'ریستوراں کے لیے آف لائن آرڈر سسٹم' : 'Offline order system for restaurants';
  String get activateTitle => isUrdu ? 'لائیسنس فعال کریں' : 'Activate your license';
  String get activateHint => isUrdu
      ? 'اگر آپ کے پاس لائیسنس ہے تو نیچے درج کریں۔ نہیں تو واٹس ایپ پر رابطہ کریں۔'
      : 'Enter your license key if you already have one, or contact us on WhatsApp to purchase.';
  String get licenseKey => isUrdu ? 'لائیسنس کلید' : 'License key';
  String get licenseHint => 'ABCD-EFGH-...';
  String get activate => isUrdu ? 'فعال کریں' : 'Activate';
  String get contactWhatsApp => isUrdu ? 'واٹس ایپ پر لائیسنس خریدیں' : 'Buy license on WhatsApp';
  String get whatsAppSub => isUrdu
      ? 'ماہانہ سبسکرپشن اور سپورٹ کے لیے پیغام بھیجیں'
      : 'Message us for monthly subscription and support';
  String get continueApp => isUrdu ? 'ایپ استعمال کریں' : 'Continue to app';
  String get language => isUrdu ? 'زبان' : 'Language';
  String get english => 'English';
  String get urdu => 'اردو';
  String get chooseRole => isUrdu ? 'اپنا کردار منتخب کریں' : 'Choose your role';
  String get mainDevice => isUrdu ? 'مین ڈیوائس' : 'Main device';
  String get orderTaker => isUrdu ? 'آرڈر لینے والا' : 'Order taker';
  String get kitchen => isUrdu ? 'باورچی خانہ' : 'Kitchen';
  String get cashier => isUrdu ? 'کیشیئر' : 'Cashier';
  String get license => isUrdu ? 'لائیسنس' : 'License';
  String get currentLicense => isUrdu ? 'موجودہ لائیسنس' : 'Current license';
  String get expires => isUrdu ? 'میعاد' : 'Expires';
}
