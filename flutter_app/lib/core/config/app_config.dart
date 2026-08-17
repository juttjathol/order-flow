/// App-wide constants (support contact, API base if needed).
/// WhatsApp username (not phone) — chat without exposing personal number.
const String kSupportWhatsAppUsername = 'Jathol_Jutt';
const String kSupportWhatsApp = 'Jathol_Jutt';
const String kSupportWhatsAppMessage =
    'Hi, I need an Order Flow license key for my business.';

/// Offline grace after last successful online validation (hours).
const int kLicenseGraceHours = 48;

/// How often Main re-validates when online (hours).
const int kLicenseHeartbeatHours = 6;
